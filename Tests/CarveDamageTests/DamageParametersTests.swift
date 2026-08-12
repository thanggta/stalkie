// Tests/CarveDamageTests/DamageParametersTests.swift
import Foundation
import Testing
@testable import CarveCore
@testable import CarveDamage

/// Pure-Swift tests — no Metal device required, so these always run in CI.
/// They pin the intensity→effect mapping and the uniform layout; the seed's
/// role inside the shader is proven by the GPU renderer tests.
struct DamageParametersTests {
  @Test func everyProfileHasATuningEntry() {
    // A profile without tuning data would silently render clean forever.
    for profile in DamageProfile.allCases {
      #expect(DamageTuning.all[profile] != nil, "missing tuning for \(profile.name)")
    }
  }

  @Test func profileNamesRoundTrip() {
    for profile in DamageProfile.allCases {
      #expect(DamageProfile(rawName: profile.name) == profile)
    }
    #expect(DamageProfile(rawName: "sparkles") == nil)
  }

  @Test func rejectsUnknownProfileAndOutOfRangeIntensity() {
    #expect(DamageParameters(profile: "sparkles", intensity: 0.5, seed: 1) == nil)
    #expect(DamageParameters(profile: "block-loss", intensity: 1.5, seed: 1) == nil)
    #expect(DamageParameters(profile: "block-loss", intensity: -0.1, seed: 1) == nil)
  }

  @Test func zeroIntensityIsFullyClean() {
    // At intensity 0 every knob must collapse to "no damage". The shader
    // early-outs to the source; the parameters must agree with that.
    for profile in DamageProfile.allCases {
      let params = DamageParameters(profile: profile.name, intensity: 0, seed: 7)
      #expect(params != nil, "profile \(profile.name)")
      guard let p = params else { continue }
      #expect(p.blockThreshold == 0)
      #expect(p.bandCount == 0)
      #expect(p.tearProbability == 0)
      #expect(p.maxShift == 0)
      #expect(p.decodeFraction == 1)
      #expect(p.boundaryJitter == 0)
      #expect(p.chromaOffsetScale == 0)
      #expect(p.patchCount == 0)
      #expect(p.patchSize == 0)
    }
  }

  @Test func higherIntensityMeansMoreDamage() {
    let low = DamageParameters(profile: "block-loss", intensity: 0.3, seed: 5)!
    let high = DamageParameters(profile: "block-loss", intensity: 0.8, seed: 5)!
    #expect(high.blockThreshold > low.blockThreshold)

    let lowScan = DamageParameters(profile: "scanline-tear", intensity: 0.3, seed: 5)!
    let highScan = DamageParameters(profile: "scanline-tear", intensity: 0.8, seed: 5)!
    #expect(highScan.bandCount >= lowScan.bandCount)
    #expect(highScan.tearProbability > lowScan.tearProbability)
    #expect(highScan.maxShift > lowScan.maxShift)

    let lowDecode = DamageParameters(profile: "partial-decode", intensity: 0.3, seed: 5)!
    let highDecode = DamageParameters(profile: "partial-decode", intensity: 0.8, seed: 5)!
    #expect(lowDecode.decodeFraction > highDecode.decodeFraction)
    #expect(highDecode.boundaryJitter > lowDecode.boundaryJitter)

    let lowChroma = DamageParameters(profile: "chroma-bleed", intensity: 0.3, seed: 5)!
    let highChroma = DamageParameters(profile: "chroma-bleed", intensity: 0.8, seed: 5)!
    #expect(highChroma.chromaOffsetScale > lowChroma.chromaOffsetScale)

    let lowOver = DamageParameters(profile: "overwrite", intensity: 0.3, seed: 5)!
    let highOver = DamageParameters(profile: "overwrite", intensity: 0.8, seed: 5)!
    #expect(highOver.patchCount >= lowOver.patchCount)
    #expect(highOver.patchSize > lowOver.patchSize)
  }

  @Test func geometryKnobsDoNotDependOnIntensity() {
    // Progressive reveal needs the pattern (which blocks/bands/patches) to
    // stay put as intensity recedes; only the amount scales. Cell counts and
    // noise scales are fixed per profile for exactly this reason.
    for profile in DamageProfile.allCases {
      let low = DamageParameters(profile: profile.name, intensity: 0.2, seed: 3)!
      let high = DamageParameters(profile: profile.name, intensity: 0.9, seed: 3)!
      #expect(low.blockCells == high.blockCells)
      #expect(low.chromaRegions == high.chromaRegions)
      #expect(low.decodeNoiseScale == high.decodeNoiseScale)
      #expect(low.overwritePatternScale == high.overwritePatternScale)
    }
  }

  @Test func sameSpecProducesIdenticalParameters() {
    let spec = DamageSpec(profile: "block-loss", intensity: 0.4, seed: 8812)
    #expect(DamageParameters(spec: spec) == DamageParameters(spec: spec))
  }

  @Test func seedIsCarriedThroughIntact() {
    let spec = DamageSpec(profile: "chroma-bleed", intensity: 0.6, seed: -991)
    let params = DamageParameters(spec: spec)!
    #expect(params.seed == -991)
    // Wrapping is deterministic, so any Int seed maps to a stable UInt32.
    #expect(params.uniforms.seed == UInt32(truncatingIfNeeded: -991))
  }

  @Test func uniformStructLayoutMatchesShaderStruct() {
    // struct DamageUniforms in MetalShaders.swift packs to two float4 + four
    // uint = 48 bytes. If Swift laid this out differently, the uniform buffer
    // the shader reads would be garbage and the render would still "work".
    #expect(MemoryLayout<DamageUniforms>.size == 48)
    #expect(MemoryLayout<DamageUniforms>.alignment == 16)
    let u = DamageParameters(profile: "block-loss", intensity: 0.4, seed: 8812)!.uniforms
    #expect(u.u0.x == 0.4)
    #expect(u.profile == 0)
  }
}
