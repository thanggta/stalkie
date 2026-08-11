import Testing
@testable import CarveCore

struct ValidatorTests {
  private let damage = DamageSpec(profile: "block-loss", intensity: 0.2, seed: 1)

  private func build(
    cycleBudget: Int = 10,
    sectors: [SectorEntry]? = nil,
    questions: [VerdictQuestion]? = nil,
    fragments: [String: Fragment]? = nil
  ) -> CaseFile {
    CaseFile(
      schemaVersion: 1,
      id: "test",
      title: "T",
      cycleBudget: cycleBudget,
      sectorMap: sectors ?? [
        SectorEntry(fragmentId: "a", typeHint: .note, integrity: 0.9, carveCost: 6),
        SectorEntry(fragmentId: "b", typeHint: .note, integrity: 0.9, carveCost: 9),
      ],
      questions: questions ?? [
        VerdictQuestion(id: "q1", prompt: "Who?", options: ["x", "y"], correct: "x", supportedBy: ["a"]),
      ],
      fragments: fragments ?? [
        "a": Fragment(id: "a", type: .note, label: "A", damage: damage, content: [:]),
        "b": Fragment(id: "b", type: .note, label: "B", damage: damage, content: [:]),
      ])
  }

  private func fragment(_ id: String) -> Fragment {
    Fragment(id: id, type: .note, label: id.uppercased(), damage: damage, content: [:])
  }

  @Test func wellFormedCaseProducesNoProblems() {
    #expect(validateCase(build()).isEmpty)
  }

  @Test func inv2RejectsCaseFullyRecoverableWithinBudget() {
    // Scarcity is the entire game. A case you can exhaust has no decisions in it.
    let problems = validateCase(build(cycleBudget: 100)) // total cost is 15
    #expect(problems.contains { $0.contains("INV-2") })
  }

  @Test func inv3RejectsQuestionWithMissingSupportingFragment() {
    let problems = validateCase(build(questions: [
      VerdictQuestion(id: "q1", prompt: "Who?", options: ["x"], correct: "x", supportedBy: ["ghost"]),
    ]))
    #expect(problems.contains { $0.contains("INV-3") })
  }

  @Test func inv4RejectsOrphanFragment() {
    let problems = validateCase(build(fragments: [
      "a": fragment("a"),
      "b": fragment("b"),
      "orphan": fragment("orphan"),
    ]))
    #expect(problems.contains { $0.contains("INV-4") })
  }

  @Test func rejectsCorrectAnswerNotAmongOptions() {
    let problems = validateCase(build(questions: [
      VerdictQuestion(id: "q1", prompt: "Who?", options: ["x", "y"], correct: "z", supportedBy: ["a"]),
    ]))
    #expect(problems.contains { $0.contains("not among its options") })
  }

  @Test func rejectsSectorEntryWithNoFragmentFile() {
    let problems = validateCase(build(sectors: [
      SectorEntry(fragmentId: "nope", typeHint: .note, integrity: 0.9, carveCost: 20),
    ]))
    #expect(problems.contains { $0.contains("no fragment file") })
  }

  @Test func inv1RejectsCaseNotSolvableWithinBudget() {
    // Total cost (40) exceeds budget so INV-2 does not fire, but no set of
    // fragments supports the question within budget. This must fail if the
    // INV-1 block is deleted from validateCase.
    let problems = validateCase(build(
      cycleBudget: 10,
      sectors: [
        SectorEntry(fragmentId: "a", typeHint: .note, integrity: 0.9, carveCost: 40),
      ],
      questions: [
        VerdictQuestion(id: "q1", prompt: "Who?", options: ["x"], correct: "x", supportedBy: ["a"]),
      ],
      fragments: ["a": fragment("a")]))
    #expect(problems.contains { $0.contains("INV-1") })
  }

  @Test func inv2RejectsDuplicateSectorEntries() {
    // Regression: a duplicated sector entry inflated totalCarveCost and
    // defeated INV-2. The duplicate must be reported on its own.
    let problems = validateCase(build(sectors: [
      SectorEntry(fragmentId: "a", typeHint: .note, integrity: 0.9, carveCost: 6),
      SectorEntry(fragmentId: "a", typeHint: .note, integrity: 0.9, carveCost: 6),
    ]))
    #expect(problems.contains { $0.contains("Duplicate sector entry") })
  }
}
