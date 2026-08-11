import Foundation
import Testing
@testable import CarveCore

struct CarveEngineTests {
  private func fixture() -> CaseFile {
    CaseFile(
      schemaVersion: 1,
      id: "t",
      title: "T",
      cycleBudget: 10,
      sectorMap: [
        SectorEntry(fragmentId: "a", typeHint: .note, integrity: 0.9, carveCost: 4),
        SectorEntry(fragmentId: "b", typeHint: .note, integrity: 0.4, carveCost: 9),
      ],
      questions: [
        VerdictQuestion(
          id: "q1", prompt: "?", options: ["x"], correct: "x", supportedBy: ["a"]),
      ],
      fragments: [
        "a": Fragment(
          id: "a", type: .note, label: "A",
          damage: DamageSpec(profile: "block-loss", intensity: 0.2, seed: 1),
          content: [:]),
        "b": Fragment(
          id: "b", type: .note, label: "B",
          damage: DamageSpec(profile: "block-loss", intensity: 0.2, seed: 1),
          content: [:]),
      ]
    )
  }

  @Test func carvingSpendsCyclesAndReturnsFragment() {
    var engine = CarveEngine(caseFile: fixture())
    #expect(engine.cyclesRemaining == 10)
    let result = engine.carve("a")
    #expect(result.outcome == .ok)
    #expect(result.fragment?.id == "a")
    #expect(engine.cyclesRemaining == 6)
  }

  @Test func carvingSameFragmentTwiceDoesNotDoubleCharge() {
    // Players will re-tap. Charging twice would silently break INV-1's
    // guarantee that the case stays winnable.
    var engine = CarveEngine(caseFile: fixture())
    engine.carve("a")
    let second = engine.carve("a")
    #expect(second.outcome == .alreadyCarved)
    #expect(engine.cyclesRemaining == 6)
  }

  @Test func refusesCarveItCannotAffordAndSpendsNothing() {
    var engine = CarveEngine(caseFile: fixture())
    engine.carve("b")  // 9 of 10 spent
    let result = engine.carve("a")  // needs 4, only 1 left
    #expect(result.outcome == .insufficientCycles)
    #expect(engine.cyclesRemaining == 1)
    #expect(engine.carvedIds.contains("a") == false)
  }

  @Test func reportsUnknownFragmentsRatherThanThrowing() {
    var engine = CarveEngine(caseFile: fixture())
    #expect(engine.carve("ghost").outcome == .unknownFragment)
  }

  @Test func linksAreOrderIndependentInExposedState() {
    // FIX A: only the canonical key may be stored. If `link` stored the raw
    // pair, this fails — the canonicalization contract becomes unenforceable.
    var engine = CarveEngine(caseFile: fixture())
    engine.link("priya", "adrian")
    #expect(engine.state.linkedPairs == ["adrian|priya"])
  }

  @Test func canCarveReflectsAffordabilityAndCarveState() {
    var engine = CarveEngine(caseFile: fixture())
    #expect(engine.canCarve("a"))  // affordable initially
    #expect(engine.canCarve("ghost") == false)  // no sector entry
    engine.carve("a")
    #expect(engine.canCarve("a") == false)  // already carved

    var broke = CarveEngine(caseFile: fixture())
    broke.carve("b")  // 9 of 10 spent
    #expect(broke.canCarve("a") == false)  // needs 4, only 1 left
  }

  @Test func engineRestoresFromPersistedState() throws {
    // FIX B: all four state fields must survive encode/decode. If any one of
    // carved/links/answered/spent were dropped from Codable, the decoded
    // engine would differ from the live one and the equality check fails.
    var engine = CarveEngine(caseFile: fixture())
    engine.carve("a")
    engine.link("priya", "adrian")
    engine.markAnswered("q1")

    let data = try JSONEncoder().encode(engine)
    let decoded = try JSONDecoder().decode(CarveEngine.self, from: data)

    #expect(decoded == engine)
    #expect(decoded.cyclesRemaining == 6)
    #expect(decoded.carvedIds == ["a"])
    #expect(decoded.state.linkedPairs == ["adrian|priya"])
  }
}
