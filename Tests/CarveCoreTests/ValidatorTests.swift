import Testing
@testable import CarveCore

struct ValidatorTests {
  private let damage = DamageSpec(profile: "block-loss", intensity: 0.2, seed: 1)

  private func build(
    sectors: [SectorEntry]? = nil,
    questions: [VerdictQuestion]? = nil,
    fragments: [String: Fragment]? = nil
  ) -> CaseFile {
    CaseFile(
      schemaVersion: 1,
      id: "test",
      title: "T",
      sectorMap: sectors ?? [
        SectorEntry(fragmentId: "a", typeHint: .note, integrity: 0.9),
        SectorEntry(fragmentId: "b", typeHint: .note, integrity: 0.9),
      ],
      questions: questions ?? [
        VerdictQuestion(id: "q1", prompt: "Who?", options: ["x", "y"], correct: "x", supportedBy: ["a"]),
      ],
      fragments: fragments ?? [
        "a": Fragment(id: "a", type: .note, label: "A", damage: damage, content: [:]),
        "b": Fragment(id: "b", type: .note, label: "B", damage: damage, content: [:]),
      ])
  }

  private func fragment(
    _ id: String,
    hiddenUntil: [String: JSONValue]? = nil
  ) -> Fragment {
    Fragment(
      id: id, type: .note, label: id.uppercased(), damage: damage,
      hiddenUntil: hiddenUntil, content: [:])
  }

  @Test func wellFormedCaseProducesNoProblems() {
    #expect(validateCase(build()).isEmpty)
  }

  @Test func inv3RejectsQuestionWithMissingSupportingFragment() {
    let problems = validateCase(build(questions: [
      VerdictQuestion(id: "q1", prompt: "Who?", options: ["x"], correct: "x", supportedBy: ["ghost"]),
    ]))
    #expect(problems.contains { $0.contains("INV-3") })
  }

  @Test func inv3RejectsSupportingFragmentBehindUnreachableGate() {
    // INV-3 after DR-11: supporting evidence must be reachable through unlocks,
    // not merely present as a file. If this check is deleted, a dead-end gate
    // still "supports" a question the player can never open.
    let problems = validateCase(build(
      sectors: [SectorEntry(fragmentId: "a", typeHint: .note, integrity: 0.9)],
      questions: [
        VerdictQuestion(
          id: "q1", prompt: "Who?", options: ["x"], correct: "x", supportedBy: ["secret"]),
      ],
      fragments: [
        "a": fragment("a"),
        // Gates on itself — present as a file, never reachable.
        "secret": fragment("secret", hiddenUntil: ["carved": .string("secret")]),
      ]))
    #expect(problems.contains { $0.contains("INV-3") && $0.contains("secret") })
  }

  @Test func inv4RejectsOrphanFragmentWithoutGate() {
    let problems = validateCase(build(fragments: [
      "a": fragment("a"),
      "b": fragment("b"),
      "orphan": fragment("orphan"),
    ]))
    #expect(problems.contains { $0.contains("INV-4") && $0.contains("orphan") })
  }

  @Test func inv4AcceptsFragmentReachableOnlyViaHiddenUntil() {
    // Sector map is not the only path. A gated fragment that opens after a
    // sector-map carve must count as reachable, or discovery cases fail validation.
    let problems = validateCase(build(
      sectors: [SectorEntry(fragmentId: "a", typeHint: .note, integrity: 0.9)],
      questions: [
        VerdictQuestion(id: "q1", prompt: "Who?", options: ["x"], correct: "x", supportedBy: ["secret"]),
      ],
      fragments: [
        "a": fragment("a"),
        "secret": fragment("secret", hiddenUntil: ["carved": .string("a")]),
      ]))
    #expect(problems.isEmpty, "problems: \(problems)")
  }

  @Test func inv4RejectsFragmentWhoseGateCanNeverOpen() {
    let problems = validateCase(build(
      sectors: [SectorEntry(fragmentId: "a", typeHint: .note, integrity: 0.9)],
      fragments: [
        "a": fragment("a"),
        "b": fragment("b"),
        // Needs b, but b is not on the sector map and has no gate of its own.
        "secret": fragment("secret", hiddenUntil: ["carved": .string("b")]),
      ]))
    #expect(problems.contains { $0.contains("INV-4") && $0.contains("secret") })
  }

  @Test func rejectsUnlockCycleAsHardFailure() {
    // Deadlock detector: if this never fires, authors can ship A↔B gates and
    // the player softlocks. Mutation target — delete the cycle check and this fails.
    let problems = validateCase(build(
      sectors: [SectorEntry(fragmentId: "seed", typeHint: .note, integrity: 0.9)],
      fragments: [
        "seed": fragment("seed"),
        "a": fragment("a", hiddenUntil: ["carved": .string("b")]),
        "b": fragment("b", hiddenUntil: ["carved": .string("a")]),
      ]))
    #expect(problems.contains { $0.contains("Unlock cycle") })
  }

  @Test func rejectsSelfGatingFragmentAsCycle() {
    let problems = validateCase(build(
      sectors: [SectorEntry(fragmentId: "seed", typeHint: .note, integrity: 0.9)],
      fragments: [
        "seed": fragment("seed"),
        "loop": fragment("loop", hiddenUntil: ["carved": .string("loop")]),
      ]))
    #expect(problems.contains { $0.contains("Unlock cycle") || $0.contains("INV-4") })
  }

  @Test func rejectsCorrectAnswerNotAmongOptions() {
    let problems = validateCase(build(questions: [
      VerdictQuestion(id: "q1", prompt: "Who?", options: ["x", "y"], correct: "z", supportedBy: ["a"]),
    ]))
    #expect(problems.contains { $0.contains("not among its options") })
  }

  @Test func rejectsSectorEntryWithNoFragmentFile() {
    let problems = validateCase(build(sectors: [
      SectorEntry(fragmentId: "nope", typeHint: .note, integrity: 0.9),
    ]))
    #expect(problems.contains { $0.contains("no fragment file") })
  }

  @Test func rejectsDuplicateSectorEntries() {
    let problems = validateCase(build(sectors: [
      SectorEntry(fragmentId: "a", typeHint: .note, integrity: 0.9),
      SectorEntry(fragmentId: "a", typeHint: .note, integrity: 0.9),
    ]))
    #expect(problems.contains { $0.contains("Duplicate sector entry") })
  }

  @Test func rejectsHiddenUntilOutsideSixPredicateGrammar() {
    // INV-5 still binds — more so now that gates drive control flow.
    let problems = validateCase(build(
      sectors: [SectorEntry(fragmentId: "a", typeHint: .note, integrity: 0.9)],
      fragments: [
        "a": fragment("a"),
        "bad": fragment("bad", hiddenUntil: ["eval": .string("true")]),
      ]))
    #expect(problems.contains { $0.contains("hiddenUntil") && $0.contains("grammar") })
  }
}
