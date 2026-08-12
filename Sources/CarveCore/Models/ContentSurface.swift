// Sources/CarveCore/Models/ContentSurface.swift
// Stable app-surface identifiers for case content (DR-13).
// Case JSON uses these strings; real platform display names live only in
// PhoneAppLabels (CarveShell). Reverting brands is a config edit, not a rewrite.

/// Where a fragment is presented. Medium type (`thread`/`image`/…) stays orthogonal.
public enum ContentSurface: String, Codable, CaseIterable, Sendable, Equatable {
  case messages
  case notes
  case photos
  case phone
  case maps
  case photoSocial = "photo_social"
  case ephemeralChat = "ephemeral_chat"

  /// Default surface when authors omit `surface` (backward-compatible five_minutes).
  public static func defaultSurface(for type: FragmentType, recordKind: String?) -> ContentSurface {
    switch type {
    case .thread: return .messages
    case .note: return .notes
    case .image: return .photos
    case .audio: return .phone
    case .record:
      if recordKind == "location" { return .maps }
      return .phone
    }
  }

  /// Type × surface pairs the shell knows how to host.
  public static func isAllowed(type: FragmentType, surface: ContentSurface, recordKind: String?)
    -> Bool
  {
    switch (type, surface) {
    case (.thread, .messages), (.thread, .photoSocial), (.thread, .ephemeralChat):
      return true
    case (.note, .notes):
      return true
    case (.image, .photos), (.image, .photoSocial):
      return true
    case (.record, .phone):
      return recordKind == nil
        || recordKind == "call_log"
        || recordKind == "transaction"
    case (.record, .maps):
      return recordKind == nil || recordKind == "location"
    case (.record, .photoSocial):
      return recordKind == nil || recordKind == "social_profile"
    case (.audio, .phone):
      return true
    default:
      return false
    }
  }
}
