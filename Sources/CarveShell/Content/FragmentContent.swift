// Sources/CarveShell/Content/FragmentContent.swift
// Typed views of fragment.content. Parsing only — no game rules.

import Foundation
import CarveCore

public struct ThreadParticipant: Equatable, Sendable {
  public let entityId: String
  public let display: String
}

public struct ThreadMessage: Equatable, Sendable, Identifiable {
  public var id: String { "\(at)|\(from)|\(text)" }
  public let at: String
  public let from: String
  public let text: String
  /// Author-flagged unrecovered span. Render █ with corrupt styling; the
  /// engine never invents these (content-schema §3.1).
  public let corrupt: Bool
  /// Ephemeral delivery state when authored (opened/delivered/screenshot).
  public let state: String?
  public let ephemeral: Bool
}

public struct ThreadContent: Equatable, Sendable {
  public let participants: [ThreadParticipant]
  public let messages: [ThreadMessage]
  /// Snapchat-style streak when authored on ephemeral_chat surface.
  public let streakDays: Int?
  public let handle: String?

  public func displayName(for entityId: String) -> String {
    participants.first { $0.entityId == entityId }?.display ?? entityId
  }

  /// The counterparty relative to the device owner (first non-eli, else second).
  public var counterpartyDisplay: String {
    counterpartyDisplay(ownerEntityId: nil)
  }

  public func counterpartyDisplay(ownerEntityId: String?) -> String {
    let owner = resolvedOwner(ownerEntityId)
    if let owner,
      let other = participants.first(where: { $0.entityId != owner })
    {
      return other.display
    }
    return participants.dropFirst().first?.display ?? labelFallback
  }

  public func isFromOwner(_ from: String, ownerEntityId: String?) -> Bool {
    from == resolvedOwner(ownerEntityId)
  }

  private func resolvedOwner(_ ownerEntityId: String?) -> String? {
    if let ownerEntityId, !ownerEntityId.isEmpty { return ownerEntityId }
    return participants.first?.entityId
  }

  private var labelFallback: String { participants.first?.display ?? "Thread" }
}

public struct NoteContent: Equatable, Sendable {
  public let title: String
  public let body: String
  public let modifiedAt: String?
}

public struct RecordContent: Equatable, Sendable {
  public let kind: String
  public let columns: [String]
  public let rows: [[JSONValue]]
}

public struct LocationVisit: Equatable, Sendable, Identifiable {
  public var id: String { "\(at)|\(label)" }
  public let at: String
  public let label: String
  public let durationMin: Int?
  /// Normalized map pin 0…1 (fictional local geometry only).
  public let x: Double
  public let y: Double
  public let placeId: String?
}

public struct LocationTimeline: Equatable, Sendable {
  public let regionName: String
  public let visits: [LocationVisit]
}

public struct SocialProfile: Equatable, Sendable {
  public let entityId: String
  public let handle: String
  public let displayName: String
  public let bio: String
  public let posts: Int
  public let followers: Int
  public let following: Int
  public let hasStory: Bool
}

public struct SocialComment: Equatable, Sendable, Identifiable {
  public var id: String { "\(from)|\(text)" }
  public let from: String
  public let text: String
}

public struct ImageContent: Equatable, Sendable {
  public let source: String
  public let capturedAt: String?
  public let exifIntact: Bool?
  public let depicts: [String]
  public let caption: String?
  public let likes: Int?
  public let authorEntityId: String?
  public let handle: String?
  public let comments: [SocialComment]
}

public enum FragmentContentError: Error, Equatable {
  case missingField(String)
  case wrongType(String)
}

public enum FragmentContent {
  public static func thread(_ fragment: Fragment) throws -> ThreadContent {
    let content = fragment.content
    let rawParticipants = try array(content, "participants")
    let participants: [ThreadParticipant] = try rawParticipants.map { item in
      guard case .object(let obj) = item else {
        throw FragmentContentError.wrongType("participants[]")
      }
      return ThreadParticipant(
        entityId: try string(obj, "entityId"),
        display: try string(obj, "display"))
    }
    let rawMessages = try array(content, "messages")
    let messages: [ThreadMessage] = try rawMessages.map { item in
      guard case .object(let obj) = item else {
        throw FragmentContentError.wrongType("messages[]")
      }
      return ThreadMessage(
        at: try string(obj, "at"),
        from: try string(obj, "from"),
        text: try string(obj, "text"),
        corrupt: bool(obj, "corrupt") ?? false,
        state: optionalString(obj, "state"),
        ephemeral: bool(obj, "ephemeral") ?? false)
    }
    let streak: Int?
    if let n = number(content, "streakDays") {
      streak = Int(n)
    } else {
      streak = nil
    }
    return ThreadContent(
      participants: participants,
      messages: messages,
      streakDays: streak,
      handle: optionalString(content, "handle"))
  }

  public static func note(_ fragment: Fragment) throws -> NoteContent {
    let content = fragment.content
    return NoteContent(
      title: try string(content, "title"),
      body: try string(content, "body"),
      modifiedAt: optionalString(content, "modifiedAt"))
  }

  public static func record(_ fragment: Fragment) throws -> RecordContent {
    let content = fragment.content
    let columns: [String]
    if content["columns"] != nil {
      columns = try array(content, "columns").compactMap { value -> String? in
        if case .string(let s) = value { return s }
        return nil
      }
    } else {
      columns = []
    }
    let rows: [[JSONValue]]
    if content["rows"] != nil {
      rows = try array(content, "rows").map { row -> [JSONValue] in
        if case .array(let cells) = row { return cells }
        throw FragmentContentError.wrongType("rows[]")
      }
    } else {
      rows = []
    }
    return RecordContent(
      kind: try string(content, "kind"),
      columns: columns,
      rows: rows)
  }

  /// Maps timeline: prefers rich `visits[]`, falls back to classic columns/rows.
  public static func locationTimeline(_ fragment: Fragment) throws -> LocationTimeline {
    let content = fragment.content
    let regionName: String
    if case .object(let region) = content["region"],
      case .string(let name) = region["name"]
    {
      regionName = name
    } else {
      regionName = "Nearby"
    }

    if let rawVisits = content["visits"], case .array(let arr) = rawVisits, !arr.isEmpty {
      let visits: [LocationVisit] = try arr.map { item in
        guard case .object(let obj) = item else {
          throw FragmentContentError.wrongType("visits[]")
        }
        return LocationVisit(
          at: try string(obj, "at"),
          label: try string(obj, "label"),
          durationMin: number(obj, "durationMin").map { Int($0) },
          x: number(obj, "x") ?? 0.5,
          y: number(obj, "y") ?? 0.5,
          placeId: optionalString(obj, "placeId"))
      }
      return LocationTimeline(regionName: regionName, visits: visits)
    }

    // Classic table shape used by early five_minutes drafts.
    let record = try self.record(fragment)
    let atIdx = record.columns.firstIndex(of: "at") ?? 0
    let labelIdx = record.columns.firstIndex(of: "label") ?? 1
    let durIdx = record.columns.firstIndex(of: "durationMin")
    var visits: [LocationVisit] = []
    for (i, row) in record.rows.enumerated() {
      let at: String
      if atIdx < row.count, case .string(let s) = row[atIdx] { at = s } else { at = "" }
      let label: String
      if labelIdx < row.count, case .string(let s) = row[labelIdx] {
        label = s
      } else {
        label = "Unknown"
      }
      var duration: Int?
      if let durIdx, durIdx < row.count, case .number(let n) = row[durIdx] {
        duration = Int(n)
      }
      let t = Double(i + 1) / Double(max(record.rows.count + 1, 2))
      visits.append(
        LocationVisit(
          at: at,
          label: label,
          durationMin: duration,
          x: 0.25 + t * 0.5,
          y: 0.3 + Double(i % 3) * 0.15,
          placeId: nil))
    }
    return LocationTimeline(regionName: regionName, visits: visits)
  }

  public static func socialProfile(_ fragment: Fragment) throws -> SocialProfile {
    let content = fragment.content
    return SocialProfile(
      entityId: try string(content, "entityId"),
      handle: try string(content, "handle"),
      displayName: try string(content, "displayName"),
      bio: optionalString(content, "bio") ?? "",
      posts: Int(number(content, "posts") ?? 0),
      followers: Int(number(content, "followers") ?? 0),
      following: Int(number(content, "following") ?? 0),
      hasStory: bool(content, "hasStory") ?? false)
  }

  public static func image(_ fragment: Fragment) throws -> ImageContent {
    let content = fragment.content
    let depicts: [String]
    if let raw = content["depicts"], case .array(let arr) = raw {
      depicts = arr.compactMap {
        if case .string(let s) = $0 { return s }
        return nil
      }
    } else {
      depicts = []
    }
    var comments: [SocialComment] = []
    if let raw = content["comments"], case .array(let arr) = raw {
      comments = arr.compactMap { item in
        guard case .object(let obj) = item,
          case .string(let from) = obj["from"],
          case .string(let text) = obj["text"]
        else { return nil }
        return SocialComment(from: from, text: text)
      }
    }
    return ImageContent(
      source: try string(content, "source"),
      capturedAt: optionalString(content, "capturedAt"),
      exifIntact: bool(content, "exifIntact"),
      depicts: depicts,
      caption: optionalString(content, "caption"),
      likes: number(content, "likes").map { Int($0) },
      authorEntityId: optionalString(content, "authorEntityId"),
      handle: optionalString(content, "handle"),
      comments: comments)
  }

  // MARK: - JSON helpers

  private static func string(_ obj: [String: JSONValue], _ key: String) throws -> String {
    guard let value = obj[key] else { throw FragmentContentError.missingField(key) }
    guard case .string(let s) = value else { throw FragmentContentError.wrongType(key) }
    return s
  }

  private static func optionalString(_ obj: [String: JSONValue], _ key: String) -> String? {
    guard let value = obj[key], case .string(let s) = value else { return nil }
    return s
  }

  private static func bool(_ obj: [String: JSONValue], _ key: String) -> Bool? {
    guard let value = obj[key], case .bool(let b) = value else { return nil }
    return b
  }

  private static func number(_ obj: [String: JSONValue], _ key: String) -> Double? {
    guard let value = obj[key], case .number(let n) = value else { return nil }
    return n
  }

  private static func array(_ obj: [String: JSONValue], _ key: String) throws -> [JSONValue] {
    guard let value = obj[key] else { throw FragmentContentError.missingField(key) }
    guard case .array(let arr) = value else { throw FragmentContentError.wrongType(key) }
    return arr
  }
}
