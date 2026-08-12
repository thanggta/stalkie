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
}

public struct CaseFile: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let id: String
  public let title: String
  /// Device owner entity id. Threads treat this person as "me". Optional for
  /// older cases; when absent, the first authored participant is the owner.
  public let ownerEntityId: String?
  public let sectorMap: [SectorEntry]
  public let questions: [VerdictQuestion]
  public let fragments: [String: Fragment]

  public init(
    schemaVersion: Int,
    id: String,
    title: String,
    ownerEntityId: String? = nil,
    sectorMap: [SectorEntry],
    questions: [VerdictQuestion],
    fragments: [String: Fragment]
  ) {
    self.schemaVersion = schemaVersion
    self.id = id
    self.title = title
    self.ownerEntityId = ownerEntityId
    self.sectorMap = sectorMap
    self.questions = questions
    self.fragments = fragments
  }

  public func sectorFor(_ fragmentId: String) -> SectorEntry? {
    sectorMap.first { $0.fragmentId == fragmentId }
  }
}
