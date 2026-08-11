import Testing
@testable import CarveCore

struct PredicateTests {
  private func makeState(
    carved: Set<String> = [],
    linked: Set<String> = [],
    answered: Set<String> = []
  ) -> GameState {
    GameState(
      carvedFragmentIds: carved,
      linkedPairs: linked,
      answeredQuestionIds: answered
    )
  }

  @Test func carvedPredicateTrueOnlyAfterRecovered() throws {
    let p = try parsePredicate(["carved": .string("thread_001")])
    #expect(p.evaluate(makeState()) == false)
    #expect(p.evaluate(makeState(carved: ["thread_001"])) == true)
  }

  @Test func linkedPredicateRequiresCanonicalForm() throws {
    // FIX A: only the canonical key may unlock the gate. The raw reversed
    // ordering must not, or the canonicalization contract becomes
    // unenforceable.
    let p = try parsePredicate(["linked": .array([.string("adrian"), .string("priya")])])
    #expect(p.evaluate(makeState(linked: ["adrian|priya"])) == true)
    #expect(p.evaluate(makeState(linked: ["priya|adrian"])) == false)
    // A forward-only raw-order fallback would pass in the reversed-argument
    // direction; the read path must reject it in BOTH argument orders.
    #expect(makeState(linked: ["priya|adrian"]).hasLink("priya", "adrian") == false)
  }

  @Test func allRequiresEveryChildAnyRequiresOne() throws {
    let all = try parsePredicate([
      "all": .array([
        .object(["carved": .string("a")]),
        .object(["carved": .string("b")]),
      ]),
    ])
    #expect(all.evaluate(makeState(carved: ["a"])) == false)
    #expect(all.evaluate(makeState(carved: ["a", "b"])) == true)

    let any = try parsePredicate([
      "any": .array([
        .object(["carved": .string("a")]),
        .object(["carved": .string("b")]),
      ]),
    ])
    #expect(any.evaluate(makeState(carved: ["a"])) == true)
  }

  @Test func notInvertsItsChild() throws {
    let p = try parsePredicate(["not": .object(["carved": .string("a")])])
    #expect(p.evaluate(makeState()) == true)
    #expect(p.evaluate(makeState(carved: ["a"])) == false)
  }

  @Test func rejectsPredicateOutsideSixKeyGrammar() throws {
    // INV-5: no expression evaluator, no scripting hook, ever.
    // The message assertion keeps this discriminating: it must fail if a 7th
    // key were accepted and rejected only by the switch's default path.
    expectUnknownPredicate(["eval": .string(#"carved("a") && true"#)])
    expectUnknownPredicate(["scriptRef": .string("unlock.js")])
  }

  private func expectUnknownPredicate(_ object: [String: JSONValue]) {
    do {
      _ = try parsePredicate(object)
      Issue.record("expected PredicateFormatError for \(object)")
    } catch let e as PredicateFormatError {
      #expect(e.message.contains("Unknown predicate"))
    } catch {
      Issue.record("expected PredicateFormatError, got \(error)")
    }
  }

  @Test func rejectsPredicateWithMoreThanOneKey() throws {
    #expect(throws: PredicateFormatError.self) {
      try parsePredicate(["carved": .string("a"), "answered": .string("q1")])
    }
  }

  @Test func rejectsMalformedPredicateElements() throws {
    // FIX B: cast-free pattern matching must throw, never crash, on malformed
    // elements.
    #expect(throws: PredicateFormatError.self) {
      try parsePredicate(["carved": .number(42)])
    }
    #expect(throws: PredicateFormatError.self) {
      try parsePredicate(["answered": .number(42)])
    }
    #expect(throws: PredicateFormatError.self) {
      try parsePredicate(["linked": .array([.string("a")])])
    }
    #expect(throws: PredicateFormatError.self) {
      try parsePredicate(["linked": .array([.number(1), .number(2)])])
    }
    #expect(throws: PredicateFormatError.self) {
      try parsePredicate(["all": .string("x")])
    }
    #expect(throws: PredicateFormatError.self) {
      try parsePredicate(["all": .array([])])
    }
    #expect(throws: PredicateFormatError.self) {
      try parsePredicate(["not": .string("x")])
    }
    #expect(throws: PredicateFormatError.self) {
      try parsePredicate(["any": .array([.string("a")])])
    }
  }
}
