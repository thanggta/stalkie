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
  /// Declarative unlock gate. Nil means visible when listed on the sector map
  /// (or always once reachability has admitted it). Evaluated via the six
  /// predicates in `Predicate.swift` — never an expression string (INV-5).
  public let hiddenUntil: [String: JSONValue]?
  /// Stable presentation surface (DR-13). Never a brand string.
  public let surface: ContentSurface
  public let content: [String: JSONValue]

  public init(
    id: String,
    type: FragmentType,
    label: String,
    damage: DamageSpec,
    hiddenUntil: [String: JSONValue]? = nil,
    surface: ContentSurface? = nil,
    content: [String: JSONValue]
  ) {
    self.id = id
    self.type = type
    self.label = label
    self.damage = damage
    self.hiddenUntil = hiddenUntil
    let kind: String? = {
      guard type == .record, case .string(let k) = content["kind"] else { return nil }
      return k
    }()
    self.surface = surface ?? ContentSurface.defaultSurface(for: type, recordKind: kind)
    self.content = content
  }

  public var recordKind: String? {
    guard type == .record, case .string(let k) = content["kind"] else { return nil }
    return k
  }
}
