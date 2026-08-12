// Tests/CarveDamageTests/DamageRendererTests.swift
import Foundation
import Metal
import Testing
@testable import CarveCore
@testable import CarveDamage

// MARK: - Helpers

/// A smooth analytic gradient: deterministic at any resolution, so cross-size
/// comparisons sample "the same image" regardless of pixel count.
private func analyticSource(width: Int, height: Int) -> [UInt8] {
  var bytes = [UInt8]()
  bytes.reserveCapacity(width * height * 4)
  for y in 0..<height {
    let v = Double(y) / Double(height)
    for x in 0..<width {
      let u = Double(x) / Double(width)
      let r = 0.5 + 0.5 * sin(2 * Double.pi * (3 * u + 0.1))
      let g = 0.5 + 0.5 * sin(2 * Double.pi * (2 * v + 0.3))
      let b = 0.5 + 0.5 * sin(2 * Double.pi * (u + v + 0.5))
      bytes.append(UInt8(clamping: Int(r * 255)))
      bytes.append(UInt8(clamping: Int(g * 255)))
      bytes.append(UInt8(clamping: Int(b * 255)))
      bytes.append(255)
    }
  }
  return bytes
}

/// The two renders evaluate the shader at fragment centers uv=(x+0.5)/w, so
/// 64-render pixel (x,y) and 128-render pixel (2x,2y) sit 1/256 apart in
/// normalized space. A pixel within 1/256 of a feature boundary can
/// legitimately flip between the sizes — that is a sub-1% band in practice.
/// A shader using pixel-space geometry instead (a get_width()-based grid)
/// moves whole features, driving the mismatch to tens of percent. The
/// mismatch FRACTION is therefore the honest discriminator: healthy renders
/// measure under 1%, and 5% leaves a wide margin in both directions.
private func viewSizeMismatchFraction(render64: [UInt8], render128: [UInt8]) -> Double {
  var mismatched = 0
  for y in 0..<64 {
    for x in 0..<64 {
      let i64 = (y * 64 + x) * 4
      let i128 = ((2 * y) * 128 + 2 * x) * 4
      for c in 0..<3 {
        if abs(Int(render64[i64 + c]) - Int(render128[i128 + c])) > 4 {
          mismatched += 1
          break
        }
      }
    }
  }
  return Double(mismatched) / Double(64 * 64)
}

// MARK: - Tests

struct DamageRendererTests {
  private let specs: [(name: String, spec: DamageSpec)] = [
    ("block-loss", DamageSpec(profile: "block-loss", intensity: 0.5, seed: 8812)),
    ("scanline-tear", DamageSpec(profile: "scanline-tear", intensity: 0.5, seed: 8812)),
    ("partial-decode", DamageSpec(profile: "partial-decode", intensity: 0.5, seed: 8812)),
    ("chroma-bleed", DamageSpec(profile: "chroma-bleed", intensity: 0.5, seed: 8812)),
    ("overwrite", DamageSpec(profile: "overwrite", intensity: 0.5, seed: 8812)),
  ]

  private func renderer() throws -> DamageRenderer {
    try DamageRenderer()
  }

  @Test(.disabled(if: MTLCreateSystemDefaultDevice() == nil, "No Metal device — GPU determinism tests cannot run here."))
  func sameSeedRendersIdenticallyTwice() throws {
    let renderer = try renderer()
    let source = analyticSource(width: 64, height: 64)
    for entry in specs {
      let first = try renderer.render(spec: entry.spec, sourceBytes: source, width: 64, height: 64)
      let second = try renderer.render(spec: entry.spec, sourceBytes: source, width: 64, height: 64)
      #expect(first == second, "\(entry.name): two renders of the same spec must be byte-identical")
    }
  }

  @Test(.disabled(if: MTLCreateSystemDefaultDevice() == nil, "No Metal device — GPU determinism tests cannot run here."))
  func differentSeedChangesRenderedOutput() throws {
    // The mutation this guards: a shader that ignores its seed uniform. If it
    // did, different seeds would render identically and this test would fail.
    let renderer = try renderer()
    let source = analyticSource(width: 64, height: 64)
    for entry in specs {
      let seedA = DamageSpec(profile: entry.spec.profile, intensity: entry.spec.intensity, seed: 8812)
      let seedB = DamageSpec(profile: entry.spec.profile, intensity: entry.spec.intensity, seed: 8813)
      let a = try renderer.render(spec: seedA, sourceBytes: source, width: 64, height: 64)
      let b = try renderer.render(spec: seedB, sourceBytes: source, width: 64, height: 64)
      #expect(a != b, "\(entry.name): a different seed must produce different damage")
    }
  }

  @Test(.disabled(if: MTLCreateSystemDefaultDevice() == nil, "No Metal device — GPU determinism tests cannot run here."))
  func differentIntensityChangesRenderedOutput() throws {
    let renderer = try renderer()
    let source = analyticSource(width: 64, height: 64)
    for entry in specs {
      let mild = DamageSpec(profile: entry.spec.profile, intensity: 0.3, seed: 8812)
      let heavy = DamageSpec(profile: entry.spec.profile, intensity: 0.7, seed: 8812)
      let a = try renderer.render(spec: mild, sourceBytes: source, width: 64, height: 64)
      let b = try renderer.render(spec: heavy, sourceBytes: source, width: 64, height: 64)
      #expect(a != b, "\(entry.name): a different intensity must produce different damage")
    }
  }

  @Test(.disabled(if: MTLCreateSystemDefaultDevice() == nil, "No Metal device — GPU determinism tests cannot run here."))
  func zeroIntensityRendersTheSourceExactly() throws {
    let renderer = try renderer()
    let source = analyticSource(width: 64, height: 64)
    for entry in specs {
      let clean = DamageSpec(profile: entry.spec.profile, intensity: 0, seed: entry.spec.seed)
      let output = try renderer.render(spec: clean, sourceBytes: source, width: 64, height: 64)
      #expect(output == source, "\(entry.name): intensity 0 must render the clean source, byte for byte")
    }
  }

  @Test(.disabled(if: MTLCreateSystemDefaultDevice() == nil, "No Metal device — GPU determinism tests cannot run here."))
  func damageActuallyChangesTheImage() throws {
    // The mutation this guards: a shader that broke to a passthrough would
    // "render" fine, match the source byte-for-byte, and every determinism
    // test above would trivially pass.
    let renderer = try renderer()
    let source = analyticSource(width: 64, height: 64)
    for entry in specs {
      let output = try renderer.render(spec: entry.spec, sourceBytes: source, width: 64, height: 64)
      #expect(output != source, "\(entry.name): damage must actually alter the image")
    }
  }

  @Test(.disabled(if: MTLCreateSystemDefaultDevice() == nil, "No Metal device — GPU determinism tests cannot run here."))
  func renderIsUnaffectedByWallClockTime() throws {
    // The API has no time input, so this should be trivially true — the sleep
    // makes it a real check against a shader that reached for the clock or an
    // unseeded random.
    let renderer = try renderer()
    let source = analyticSource(width: 64, height: 64)
    for entry in specs {
      let before = try renderer.render(spec: entry.spec, sourceBytes: source, width: 64, height: 64)
      Thread.sleep(forTimeInterval: 0.2)
      let after = try renderer.render(spec: entry.spec, sourceBytes: source, width: 64, height: 64)
      #expect(before == after, "\(entry.name): rendering must not vary with time")
    }
  }

  @Test(.disabled(if: MTLCreateSystemDefaultDevice() == nil, "No Metal device — GPU determinism tests cannot run here."))
  func viewSizeDoesNotMoveTheDamagePattern() throws {
    let renderer = try renderer()
    for entry in specs {
      let small = try renderer.render(
        spec: entry.spec, sourceBytes: analyticSource(width: 64, height: 64), width: 64, height: 64)
      let large = try renderer.render(
        spec: entry.spec, sourceBytes: analyticSource(width: 128, height: 128), width: 128, height: 128)
      let fraction = viewSizeMismatchFraction(render64: small, render128: large)
      #expect(
        fraction < 0.05,
        "\(entry.name): damage pattern moved with view size (\(String(format: "%.1f%%", fraction * 100)) of pixels disagree)")
    }
  }

  @Test(.disabled(if: MTLCreateSystemDefaultDevice() == nil, "No Metal device — GPU determinism tests cannot run here."))
  func rendererRejectsBadInput() throws {
    let renderer = try renderer()
    let source = analyticSource(width: 64, height: 64)
    let spec = DamageSpec(profile: "block-loss", intensity: 0.5, seed: 1)
    #expect(throws: DamageRenderError.self) {
      try renderer.render(spec: spec, sourceBytes: [], width: 64, height: 64)
    }
    #expect(throws: DamageRenderError.self) {
      try renderer.render(spec: spec, sourceBytes: source, width: 0, height: 64)
    }
    #expect(throws: DamageRenderError.self) {
      try renderer.render(spec: DamageSpec(profile: "sparkles", intensity: 0.5, seed: 1), sourceBytes: source, width: 64, height: 64)
    }
  }
}
