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
  public let sectorMap: [SectorEntry]
  public let questions: [VerdictQuestion]
  public let fragments: [String: Fragment]

  public func sectorFor(_ fragmentId: String) -> SectorEntry? {
    sectorMap.first { $0.fragmentId == fragmentId }
  }
}
