import Testing
@testable import CarveCore

struct SolverTests {
  private func caseWith(
    budget: Int,
    sectors: [SectorEntry],
    questions: [VerdictQuestion]
  ) -> CaseFile {
    let damage = DamageSpec(profile: "block-loss", intensity: 0.2, seed: 1)
    var fragments: [String: Fragment] = [:]
    for sector in sectors {
      fragments[sector.fragmentId] = Fragment(
        id: sector.fragmentId, type: .note, label: sector.fragmentId,
        damage: damage, content: [:])
    }
    return CaseFile(
      schemaVersion: 1,
      id: "t",
      title: "T",
      cycleBudget: budget,
      sectorMap: sectors,
      questions: questions,
      fragments: fragments)
  }

  @Test func solvableWhenCheapestSupportingFragmentFitsBudget() {
    let c = caseWith(
      budget: 10,
      sectors: [
        SectorEntry(fragmentId: "a", typeHint: .note, integrity: 0.9, carveCost: 4),
        SectorEntry(fragmentId: "b", typeHint: .note, integrity: 0.9, carveCost: 30),
      ],
      questions: [
        VerdictQuestion(id: "q1", prompt: "?", options: ["x"], correct: "x", supportedBy: ["a", "b"]),
      ])
    #expect(isSolvable(c))
  }

  @Test func unsolvableWhenEverySupportingFragmentExceedsBudget() {
    let c = caseWith(
      budget: 5,
      sectors: [
        SectorEntry(fragmentId: "a", typeHint: .note, integrity: 0.9, carveCost: 40),
        SectorEntry(fragmentId: "b", typeHint: .note, integrity: 0.9, carveCost: 30),
      ],
      questions: [
        VerdictQuestion(id: "q1", prompt: "?", options: ["x"], correct: "x", supportedBy: ["a", "b"]),
      ])
    #expect(!isSolvable(c))
  }

  @Test func sharesFragmentAcrossQuestionsRatherThanDoublePaying() {
    // 'shared' answers both questions; naive per-question summing would
    // charge 12 and wrongly report unsolvable.
    let c = caseWith(
      budget: 7,
      sectors: [
        SectorEntry(fragmentId: "shared", typeHint: .note, integrity: 0.9, carveCost: 6),
      ],
      questions: [
        VerdictQuestion(id: "q1", prompt: "?", options: ["x"], correct: "x", supportedBy: ["shared"]),
        VerdictQuestion(id: "q2", prompt: "?", options: ["y"], correct: "y", supportedBy: ["shared"]),
      ])
    #expect(isSolvable(c))
  }

  @Test func exactBudgetBoundaryIsSolvable() {
    let c = caseWith(
      budget: 6,
      sectors: [
        SectorEntry(fragmentId: "shared", typeHint: .note, integrity: 0.9, carveCost: 6),
      ],
      questions: [
        VerdictQuestion(id: "q1", prompt: "?", options: ["x"], correct: "x", supportedBy: ["shared"]),
      ])
    #expect(isSolvable(c))
  }
}
