import Foundation
import Testing
@testable import CarveCore

struct CarveEngineTests {
  private let damage = DamageSpec(profile: "block-loss", intensity: 0.2, seed: 1)

  private func fixture(
    sectors: [SectorEntry]? = nil,
    fragments: [String: Fragment]? = nil
  ) -> CaseFile {
    CaseFile(
      schemaVersion: 1,
      id: "t",
      title: "T",
      sectorMap: sectors ?? [
        SectorEntry(fragmentId: "a", typeHint: .note, integrity: 0.9),
        SectorEntry(fragmentId: "b", typeHint: .note, integrity: 0.4),
      ],
      questions: [
        VerdictQuestion(
          id: "q1", prompt: "?", options: ["x"], correct: "x", supportedBy: ["a"]),
      ],
      fragments: fragments ?? [
        "a": Fragment(id: "a", type: .note, label: "A", damage: damage, content: [:]),
        "b": Fragment(id: "b", type: .note, label: "B", damage: damage, content: [:]),
      ]
    )
  }

  @Test func carvingMarksFragmentWithoutSpendingABudget() {
    var engine = CarveEngine(caseFile: fixture())
    let result = engine.carve("a")
    #expect(result.outcome == .ok)
    #expect(result.fragment?.id == "a")
    #expect(engine.carvedIds == ["a"])
  }

  @Test func carvingSameFragmentTwiceIsIdempotent() {
    // Players will re-tap. Charging a cost twice used to break scarcity math;
    // now the contract is simply: already open stays open, no double-mark.
    var engine = CarveEngine(caseFile: fixture())
    engine.carve("a")
    let second = engine.carve("a")
    #expect(second.outcome == .alreadyCarved)
    #expect(engine.carvedIds == ["a"])
  }

  @Test func refusesHiddenFragmentUntilGateOpens() {
    // Discovery gating is the structure that replaced the cycle budget.
    // If hiddenUntil is ignored, this opens immediately and the case has no shape.
    let gated = fixture(
      sectors: [SectorEntry(fragmentId: "a", typeHint: .note, integrity: 0.9)],
      fragments: [
        "a": Fragment(id: "a", type: .note, label: "A", damage: damage, content: [:]),
        "secret": Fragment(
          id: "secret", type: .note, label: "S", damage: damage,
          hiddenUntil: ["carved": .string("a")], content: [:]),
      ])
    var engine = CarveEngine(caseFile: gated)
    #expect(engine.isVisible("secret") == false)
    #expect(engine.canCarve("secret") == false)
    #expect(engine.carve("secret").outcome == .hidden)

    engine.carve("a")
    #expect(engine.isVisible("secret"))
    #expect(engine.carve("secret").outcome == .ok)
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

  @Test func canCarveReflectsVisibilityAndCarveState() {
    var engine = CarveEngine(caseFile: fixture())
    #expect(engine.canCarve("a"))
    #expect(engine.canCarve("ghost") == false)
    engine.carve("a")
    #expect(engine.canCarve("a") == false)
  }

  @Test func engineRestoresFromPersistedState() throws {
    // All three state fields must survive encode/decode. If carved/links/
    // answered drop out of Codable, the decoded engine differs and equality fails.
    var engine = CarveEngine(caseFile: fixture())
    engine.carve("a")
    engine.link("priya", "adrian")
    engine.markAnswered("q1")

    let data = try JSONEncoder().encode(engine)
    let decoded = try JSONDecoder().decode(CarveEngine.self, from: data)

    #expect(decoded == engine)
    #expect(decoded.carvedIds == ["a"])
    #expect(decoded.state.linkedPairs == ["adrian|priya"])
  }

  @Test func sectorMapFragmentWithoutGateIsVisibleAtStart() {
    let engine = CarveEngine(caseFile: fixture())
    #expect(engine.isVisible("a"))
    #expect(engine.isVisible("b"))
  }

  @Test func fragmentNotOnSectorMapAndWithoutGateStaysInvisible() {
    // Orphans are a validator concern; the engine must not leak them as openable.
    let c = fixture(
      sectors: [SectorEntry(fragmentId: "a", typeHint: .note, integrity: 0.9)],
      fragments: [
        "a": Fragment(id: "a", type: .note, label: "A", damage: damage, content: [:]),
        "orphan": Fragment(id: "orphan", type: .note, label: "O", damage: damage, content: [:]),
      ])
    let engine = CarveEngine(caseFile: c)
    #expect(engine.isVisible("orphan") == false)
    #expect(engine.canCarve("orphan") == false)
  }
}
