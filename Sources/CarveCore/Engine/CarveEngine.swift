public enum CarveOutcome: String, Codable, Sendable {
  case ok, alreadyCarved, hidden, unknownFragment
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
/// Free browsing gated by discovery: a fragment is openable when it is visible
/// under the current `GameState` (sector map seed, or `hiddenUntil` true).
/// There is no cycle budget — structure comes from unlocks, not scarcity (DR-11).
public struct CarveEngine: Equatable, Codable, Sendable {
  public let caseFile: CaseFile
  public private(set) var carved: Set<String>
  public private(set) var links: Set<String>
  public private(set) var answered: Set<String>

  public init(caseFile: CaseFile) {
    self.caseFile = caseFile
    self.carved = []
    self.links = []
    self.answered = []
  }

  /// Restore pure engine progress onto a freshly loaded case (persistence).
  public init(
    caseFile: CaseFile,
    carved: Set<String>,
    links: Set<String>,
    answered: Set<String>
  ) {
    self.caseFile = caseFile
    self.carved = carved
    self.links = links
    self.answered = answered
  }

  public var carvedIds: Set<String> { carved }

  public var state: GameState {
    GameState(
      carvedFragmentIds: carved,
      linkedPairs: links,
      answeredQuestionIds: answered)
  }

  /// True when the fragment exists and its unlock gate (if any) holds.
  /// Sector-map fragments with no `hiddenUntil` are visible from the start.
  /// Gated fragments become visible when their predicate evaluates true.
  public func isVisible(_ fragmentId: String) -> Bool {
    guard let fragment = caseFile.fragments[fragmentId] else { return false }
    guard let raw = fragment.hiddenUntil else {
      return caseFile.sectorFor(fragmentId) != nil
    }
    guard let predicate = try? parsePredicate(raw) else { return false }
    return predicate.evaluate(state)
  }

  public func canCarve(_ fragmentId: String) -> Bool {
    guard caseFile.fragments[fragmentId] != nil else { return false }
    guard !carved.contains(fragmentId) else { return false }
    return isVisible(fragmentId)
  }

  public mutating func carve(_ fragmentId: String) -> CarveResult {
    guard let fragment = caseFile.fragments[fragmentId] else {
      return CarveResult(outcome: .unknownFragment, fragment: nil)
    }
    if carved.contains(fragmentId) {
      return CarveResult(outcome: .alreadyCarved, fragment: fragment)
    }
    if !isVisible(fragmentId) {
      return CarveResult(outcome: .hidden, fragment: nil)
    }
    carved.insert(fragmentId)
    return CarveResult(outcome: .ok, fragment: fragment)
  }

  public mutating func link(_ a: String, _ b: String) {
    links.insert(GameState.linkKey(a, b))
  }

  public mutating func markAnswered(_ questionId: String) {
    answered.insert(questionId)
  }
}
