import Testing
@testable import CarveCore

struct FragmentTests {
  @Test func damageSpecEqualWhenAllFieldsEqual() {
    // Determinism matters: random damage makes screenshots irreproducible
    // and bug reports useless. See docs/content-schema.md section 3.
    let a = DamageSpec(profile: "block-loss", intensity: 0.4, seed: 8812)
    let b = DamageSpec(profile: "block-loss", intensity: 0.4, seed: 8812)
    #expect(a == b)
  }

  @Test func damageSpecWithDifferentSeedsNotEqual() {
    let a = DamageSpec(profile: "block-loss", intensity: 0.4, seed: 1)
    let b = DamageSpec(profile: "block-loss", intensity: 0.4, seed: 2)
    #expect(a != b)
  }
}
