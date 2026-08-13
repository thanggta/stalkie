public struct SectorEntry: Codable, Equatable, Sendable {
  public let fragmentId: String
  public let typeHint: FragmentType
  public let integrity: Double
}

public struct VerdictQuestion: Codable, Equatable, Sendable {
  public let id: String
  public let prompt: String
  public let options: [String]
  public let correct: String
  public let supportedBy: [String]
  public let rationale: String?
  public let evidenceHint: String?

  public init(
    id: String,
    prompt: String,
    options: [String],
    correct: String,
    supportedBy: [String],
    rationale: String? = nil,
    evidenceHint: String? = nil
  ) {
    self.id = id
    self.prompt = prompt
    self.options = options
    self.correct = correct
    self.supportedBy = supportedBy
    self.rationale = rationale
    self.evidenceHint = evidenceHint
  }
}

public struct CaseFile: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let id: String
  public let title: String
  /// Device owner entity id. Threads treat this person as "me". Optional for
  /// older cases; when absent, the first authored participant is the owner.
  public let ownerEntityId: String?
  /// Optional six-predicate that must be true before Decide appears (DR-14).
  public let decideReadyWhen: [String: JSONValue]?
  public let sectorMap: [SectorEntry]
  public let questions: [VerdictQuestion]
  public let fragments: [String: Fragment]

  public init(
    schemaVersion: Int,
    id: String,
    title: String,
    ownerEntityId: String? = nil,
    decideReadyWhen: [String: JSONValue]? = nil,
    sectorMap: [SectorEntry],
    questions: [VerdictQuestion],
    fragments: [String: Fragment]
  ) {
    self.schemaVersion = schemaVersion
    self.id = id
    self.title = title
    self.ownerEntityId = ownerEntityId
    self.decideReadyWhen = decideReadyWhen
    self.sectorMap = sectorMap
    self.questions = questions
    self.fragments = fragments
  }

  public func sectorFor(_ fragmentId: String) -> SectorEntry? {
    sectorMap.first { $0.fragmentId == fragmentId }
  }
}
