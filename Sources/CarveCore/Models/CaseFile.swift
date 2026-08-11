public struct SectorEntry: Codable, Equatable, Sendable {
  public let fragmentId: String
  public let typeHint: FragmentType
  public let integrity: Double
  public let carveCost: Int
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
  public let cycleBudget: Int
  public let sectorMap: [SectorEntry]
  public let questions: [VerdictQuestion]
  public let fragments: [String: Fragment]

  public var totalCarveCost: Int { sectorMap.reduce(0) { $0 + $1.carveCost } }
  public func sectorFor(_ fragmentId: String) -> SectorEntry? {
    sectorMap.first { $0.fragmentId == fragmentId }
  }
}
