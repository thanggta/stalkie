// Sources/CarveDamage/DamageParameters.swift
import CarveCore
import Foundation

/// The five damage profiles, in shader order. The raw value is the `profile`
/// index passed to the Metal fragment shader — keep it in sync with
/// `MetalShaders.swift`'s switch, and never reorder without updating both.
public enum DamageProfile: Int, CaseIterable, Sendable, Equatable {
  case blockLoss = 0
  case scanlineTear = 1
  case partialDecode = 2
  case chromaBleed = 3
  case overwrite = 4

  public init?(rawName: String) {
    switch rawName {
    case "block-loss": self = .blockLoss
    case "scanline-tear": self = .scanlineTear
    case "partial-decode": self = .partialDecode
    case "chroma-bleed": self = .chromaBleed
    case "overwrite": self = .overwrite
    default: return nil
    }
  }

  public var name: String {
    switch self {
    case .blockLoss: return "block-loss"
    case .scanlineTear: return "scanline-tear"
    case .partialDecode: return "partial-decode"
    case .chromaBleed: return "chroma-bleed"
    case .overwrite: return "overwrite"
    }
  }
}

/// The intensity→effect mapping, as data so a non-engineer can tune a case
/// without touching shader code. `effect = knob * intensity^curve`; at
/// intensity 0 every knob collapses to zero (the fragment renders clean).
public struct DamageTuning: Sendable, Equatable {
  public let blockCells: Double
  public let blockLostAtFull: Double
  public let bandsAtFull: Double
  public let tearProbabilityAtFull: Double
  public let maxShiftAtFull: Double
  public let cleanFractionAtFull: Double
  public let boundaryJitterAtFull: Double
  public let decodeNoiseScale: Double
  public let chromaOffsetScaleAtFull: Double
  public let chromaRegions: Double
  public let patchesAtFull: Double
  public let patchSizeAtFull: Double
  public let overwritePatternScale: Double
  public let curve: Double

  public static let all: [DamageProfile: DamageTuning] = [
    .blockLoss: DamageTuning(
      blockCells: 32, blockLostAtFull: 0.8,
      bandsAtFull: 0, tearProbabilityAtFull: 0, maxShiftAtFull: 0,
      cleanFractionAtFull: 1, boundaryJitterAtFull: 0, decodeNoiseScale: 0,
      chromaOffsetScaleAtFull: 0, chromaRegions: 0,
      patchesAtFull: 0, patchSizeAtFull: 0, overwritePatternScale: 0,
      curve: 1.0),
    .scanlineTear: DamageTuning(
      blockCells: 0, blockLostAtFull: 0,
      bandsAtFull: 12, tearProbabilityAtFull: 0.7, maxShiftAtFull: 0.15,
      cleanFractionAtFull: 1, boundaryJitterAtFull: 0, decodeNoiseScale: 0,
      chromaOffsetScaleAtFull: 0, chromaRegions: 0,
      patchesAtFull: 0, patchSizeAtFull: 0, overwritePatternScale: 0,
      curve: 1.0),
    .partialDecode: DamageTuning(
      blockCells: 0, blockLostAtFull: 0,
      bandsAtFull: 0, tearProbabilityAtFull: 0, maxShiftAtFull: 0,
      cleanFractionAtFull: 0.25, boundaryJitterAtFull: 0.08, decodeNoiseScale: 64,
      chromaOffsetScaleAtFull: 0, chromaRegions: 0,
      patchesAtFull: 0, patchSizeAtFull: 0, overwritePatternScale: 0,
      curve: 1.0),
    .chromaBleed: DamageTuning(
      blockCells: 0, blockLostAtFull: 0,
      bandsAtFull: 0, tearProbabilityAtFull: 0, maxShiftAtFull: 0,
      cleanFractionAtFull: 1, boundaryJitterAtFull: 0, decodeNoiseScale: 0,
      chromaOffsetScaleAtFull: 0.03, chromaRegions: 8,
      patchesAtFull: 0, patchSizeAtFull: 0, overwritePatternScale: 0,
      curve: 1.0),
    .overwrite: DamageTuning(
      blockCells: 0, blockLostAtFull: 0,
      bandsAtFull: 0, tearProbabilityAtFull: 0, maxShiftAtFull: 0,
      cleanFractionAtFull: 1, boundaryJitterAtFull: 0, decodeNoiseScale: 0,
      chromaOffsetScaleAtFull: 0, chromaRegions: 0,
      patchesAtFull: 8, patchSizeAtFull: 0.2, overwritePatternScale: 128,
      curve: 1.0),
  ]
}

/// The seed- and intensity-derived values a profile needs. Geometry (which
/// blocks/bands/patches) is decided inside the shader from `seed` alone, so
/// the pattern is stable as intensity changes — that stability is what makes
/// progressive reveal (spend more cycles, same damage recedes) possible.
public struct DamageParameters: Equatable, Sendable {
  public let profile: DamageProfile
  public let seed: Int
  public let intensity: Double

  public let blockCells: Double
  public let blockThreshold: Double
  public let bandCount: Int
  public let tearProbability: Double
  public let maxShift: Double
  public let decodeFraction: Double
  public let boundaryJitter: Double
  public let decodeNoiseScale: Double
  public let chromaOffsetScale: Double
  public let chromaRegions: Double
  public let patchCount: Int
  public let patchSize: Double
  public let overwritePatternScale: Double

  public init?(spec: DamageSpec) {
    self.init(profile: spec.profile, intensity: spec.intensity, seed: spec.seed)
  }

  public init?(profile: String, intensity: Double, seed: Int) {
    guard let profile = DamageProfile(rawName: profile),
      let tuning = DamageTuning.all[profile],
      (0.0...1.0).contains(intensity)
    else { return nil }
    let curve = tuning.curve
    func amount(_ knob: Double) -> Double { knob * pow(intensity, curve) }

    self.profile = profile
    self.seed = seed
    self.intensity = intensity
    blockCells = tuning.blockCells
    blockThreshold = amount(tuning.blockLostAtFull)
    bandCount = Int(amount(tuning.bandsAtFull).rounded())
    tearProbability = amount(tuning.tearProbabilityAtFull)
    maxShift = amount(tuning.maxShiftAtFull)
    decodeFraction = 1 - (1 - tuning.cleanFractionAtFull) * pow(intensity, curve)
    boundaryJitter = amount(tuning.boundaryJitterAtFull)
    decodeNoiseScale = tuning.decodeNoiseScale
    chromaOffsetScale = amount(tuning.chromaOffsetScaleAtFull)
    chromaRegions = tuning.chromaRegions
    patchCount = Int(amount(tuning.patchesAtFull).rounded())
    patchSize = amount(tuning.patchSizeAtFull)
    overwritePatternScale = tuning.overwritePatternScale
  }
}

extension DamageParameters {
  /// Layout must match `struct DamageUniforms` in `MetalShaders.swift`
  /// (two float4 + four uint, 48 bytes total). Verified by a unit test.
  public var uniforms: DamageUniforms {
    let i = Float(intensity)
    let zeros = SIMD4<Float>(0, 0, 0, 0)
    switch profile {
    case .blockLoss:
      return DamageUniforms(
        u0: SIMD4<Float>(i, Float(blockCells), Float(blockThreshold), 0), u1: zeros,
        seed: UInt32(truncatingIfNeeded: seed), profile: UInt32(profile.rawValue))
    case .scanlineTear:
      return DamageUniforms(
        u0: SIMD4<Float>(i, Float(bandCount), Float(tearProbability), Float(maxShift)),
        u1: zeros,
        seed: UInt32(truncatingIfNeeded: seed), profile: UInt32(profile.rawValue))
    case .partialDecode:
      return DamageUniforms(
        u0: SIMD4<Float>(i, Float(decodeFraction), Float(boundaryJitter), Float(decodeNoiseScale)),
        u1: zeros,
        seed: UInt32(truncatingIfNeeded: seed), profile: UInt32(profile.rawValue))
    case .chromaBleed:
      return DamageUniforms(
        u0: SIMD4<Float>(i, Float(chromaOffsetScale), Float(chromaRegions), 0), u1: zeros,
        seed: UInt32(truncatingIfNeeded: seed), profile: UInt32(profile.rawValue))
    case .overwrite:
      return DamageUniforms(
        u0: SIMD4<Float>(i, Float(patchCount), Float(patchSize), Float(overwritePatternScale)),
        u1: zeros,
        seed: UInt32(truncatingIfNeeded: seed), profile: UInt32(profile.rawValue))
    }
  }
}

public struct DamageUniforms: Equatable, Sendable {
  public var u0: SIMD4<Float>
  public var u1: SIMD4<Float>
  public var seed: UInt32
  public var profile: UInt32
  public var _pad0: UInt32
  public var _pad1: UInt32

  public init(u0: SIMD4<Float>, u1: SIMD4<Float>, seed: UInt32, profile: UInt32) {
    self.u0 = u0
    self.u1 = u1
    self.seed = seed
    self.profile = profile
    _pad0 = 0
    _pad1 = 0
  }
}
