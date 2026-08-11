public enum CarveOutcome: String, Codable, Sendable {
  case ok, alreadyCarved, insufficientCycles, unknownFragment
}

public struct CarveResult: Equatable, Sendable {
  public let outcome: CarveOutcome
  public let fragment: Fragment?

  public init(outcome: CarveOutcome, fragment: Fragment?) {
    self.outcome = outcome
    self.fragment = fragment
  }
}

/// Pure game rules. No IO, no platform calls. See CLAUDE.md rule 3.
///
/// FIX A: value semantics. `caseFile` is `let`, so a caller cannot inject a
/// zero-cost sector entry or otherwise corrupt the rules. All mutation flows
/// through `mutating` methods.
public struct CarveEngine: Equatable, Codable, Sendable {
  public let caseFile: CaseFile
  public private(set) var carved: Set<String>
  public private(set) var links: Set<String>
  public private(set) var answered: Set<String>
  public private(set) var spent: Int

  public init(caseFile: CaseFile) {
    self.caseFile = caseFile
    self.carved = []
    self.links = []
    self.answered = []
    self.spent = 0
  }

  public var cyclesRemaining: Int { caseFile.cycleBudget - spent }
  public var carvedIds: Set<String> { carved }

  // FIX B: all four state fields are stored properties, so Codable
  // synthesis restores the session from persisted JSON for free.
  public var state: GameState {
    GameState(
      carvedFragmentIds: carved,
      linkedPairs: links,
      answeredQuestionIds: answered)
  }

  public func canCarve(_ fragmentId: String) -> Bool {
    guard let sector = caseFile.sectorFor(fragmentId), !carved.contains(fragmentId) else {
      return false
    }
    return sector.carveCost <= cyclesRemaining
  }

  public mutating func carve(_ fragmentId: String) -> CarveResult {
    guard let sector = caseFile.sectorFor(fragmentId) else {
      return CarveResult(outcome: .unknownFragment, fragment: nil)
    }
    if carved.contains(fragmentId) {
      return CarveResult(outcome: .alreadyCarved, fragment: caseFile.fragments[fragmentId])
    }
    if sector.carveCost > cyclesRemaining {
      return CarveResult(outcome: .insufficientCycles, fragment: nil)
    }
    spent += sector.carveCost
    carved.insert(fragmentId)
    return CarveResult(outcome: .ok, fragment: caseFile.fragments[fragmentId])
  }

  public mutating func link(_ a: String, _ b: String) {
    links.insert(GameState.linkKey(a, b))
  }

  public mutating func markAnswered(_ questionId: String) {
    answered.insert(questionId)
  }
}
