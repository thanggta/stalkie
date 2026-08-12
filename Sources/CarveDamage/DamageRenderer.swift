// Sources/CarveDamage/DamageRenderer.swift
import CarveCore
import Foundation
import Metal

public enum DamageRenderError: Error, Equatable {
  case metalUnavailable
  case libraryCompilationFailed(String)
  case pipelineCreationFailed(String)
  case unknownProfile(String)
  case invalidDimensions
  case sourceByteCountMismatch
  case textureCreationFailed
}

/// Applies a fragment's `damage` block to a clean RGBA8 image by rendering it
/// offscreen with the profile's Metal shader. Byte-for-byte deterministic:
/// the same `DamageSpec` and the same source produce the same bytes every
/// session, and the render takes no time, frame, or view-size input.
public final class DamageRenderer {
  private let device: MTLDevice
  private let commandQueue: MTLCommandQueue
  private let pipeline: MTLRenderPipelineState
  private let sampler: MTLSamplerState

  public init(device: MTLDevice? = nil) throws {
    guard let device = device ?? MTLCreateSystemDefaultDevice() else {
      throw DamageRenderError.metalUnavailable
    }
    self.device = device
    guard let commandQueue = device.makeCommandQueue() else {
      throw DamageRenderError.pipelineCreationFailed("command queue unavailable")
    }
    self.commandQueue = commandQueue

    let library: MTLLibrary
    do {
      library = try device.makeLibrary(source: MetalShaders.source, options: nil)
    } catch {
      throw DamageRenderError.libraryCompilationFailed(String(describing: error))
    }
    guard let vertex = library.makeFunction(name: "carve_vertex"),
      let fragment = library.makeFunction(name: "carve_damage_fragment")
    else {
      throw DamageRenderError.pipelineCreationFailed("shader functions not found")
    }

    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.vertexFunction = vertex
    descriptor.fragmentFunction = fragment
    descriptor.colorAttachments[0].pixelFormat = .rgba8Unorm
    do {
      pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
    } catch {
      throw DamageRenderError.pipelineCreationFailed(String(describing: error))
    }

    let samplerDescriptor = MTLSamplerDescriptor()
    samplerDescriptor.minFilter = .linear
    samplerDescriptor.magFilter = .linear
    samplerDescriptor.sAddressMode = .clampToEdge
    samplerDescriptor.tAddressMode = .clampToEdge
    guard let sampler = device.makeSamplerState(descriptor: samplerDescriptor) else {
      throw DamageRenderError.pipelineCreationFailed("sampler unavailable")
    }
    self.sampler = sampler
  }

  /// Applies damage to an RGBA8 source buffer (row 0 = top) and returns the
  /// damaged RGBA8 buffer at the same size.
  public func render(spec: DamageSpec, sourceBytes: [UInt8], width: Int, height: Int) throws -> [UInt8] {
    guard width > 0, height > 0 else { throw DamageRenderError.invalidDimensions }
    guard sourceBytes.count == width * height * 4 else { throw DamageRenderError.sourceByteCountMismatch }
    guard let params = DamageParameters(spec: spec) else {
      throw DamageRenderError.unknownProfile(spec.profile)
    }

    let sourceTexture = try makeTexture(width: width, height: height, bytes: sourceBytes)
    let target = try render(params: params, source: sourceTexture, width: width, height: height)
    return readBack(target, width: width, height: height)
  }

  // MARK: - Private

  private func makeTexture(width: Int, height: Int, bytes: [UInt8]) throws -> MTLTexture {
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
    descriptor.usage = [.shaderRead]
    descriptor.storageMode = .shared
    guard let texture = device.makeTexture(descriptor: descriptor) else {
      throw DamageRenderError.textureCreationFailed
    }
    bytes.withUnsafeBytes { raw in
      texture.replace(
        region: MTLRegionMake2D(0, 0, width, height),
        mipmapLevel: 0,
        withBytes: raw.baseAddress!,
        bytesPerRow: width * 4)
    }
    return texture
  }

  private func render(params: DamageParameters, source: MTLTexture, width: Int, height: Int) throws -> MTLTexture {
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
    descriptor.usage = [.renderTarget]
    descriptor.storageMode = .shared
    guard let target = device.makeTexture(descriptor: descriptor) else {
      throw DamageRenderError.textureCreationFailed
    }

    var uniforms = params.uniforms
    guard let uniformBuffer = device.makeBuffer(
      bytes: &uniforms,
      length: MemoryLayout<DamageUniforms>.size,
      options: .storageModeShared)
    else {
      throw DamageRenderError.pipelineCreationFailed("uniform buffer unavailable")
    }

    let passDescriptor = MTLRenderPassDescriptor()
    passDescriptor.colorAttachments[0].texture = target
    passDescriptor.colorAttachments[0].loadAction = .clear
    passDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

    guard let commandBuffer = commandQueue.makeCommandBuffer(),
      let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
    else {
      throw DamageRenderError.pipelineCreationFailed("command buffer unavailable")
    }
    encoder.setRenderPipelineState(pipeline)
    encoder.setFragmentTexture(source, index: 0)
    encoder.setFragmentSamplerState(sampler, index: 0)
    encoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)
    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
    encoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    return target
  }

  private func readBack(_ texture: MTLTexture, width: Int, height: Int) -> [UInt8] {
    var bytes = [UInt8](repeating: 0, count: width * height * 4)
    bytes.withUnsafeMutableBytes { raw in
      texture.getBytes(
        raw.baseAddress!,
        bytesPerRow: width * 4,
        bytesPerImage: 0,
        from: MTLRegionMake2D(0, 0, width, height),
        mipmapLevel: 0,
        slice: 0)
    }
    return bytes
  }
}
