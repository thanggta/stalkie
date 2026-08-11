public enum FragmentType: String, Codable, CaseIterable, Sendable {
  case thread, image, record, note, audio
}

public struct DamageSpec: Codable, Equatable, Sendable {
  public let profile: String
  public let intensity: Double
  public let seed: Int

  public static let allowedProfiles: Set<String> = [
    "block-loss", "scanline-tear", "partial-decode", "chroma-bleed", "overwrite",
  ]
}

public struct Fragment: Codable, Equatable, Sendable {
  public let id: String
  public let type: FragmentType
  public let label: String
  public let damage: DamageSpec
  public let content: [String: JSONValue]
}
