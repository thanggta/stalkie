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
}

public struct ThreadContent: Equatable, Sendable {
  public let participants: [ThreadParticipant]
  public let messages: [ThreadMessage]

  public func displayName(for entityId: String) -> String {
    participants.first { $0.entityId == entityId }?.display ?? entityId
  }

  /// The counterparty relative to the device owner (first non-eli, else second).
  public var counterpartyDisplay: String {
    if let other = participants.first(where: { $0.entityId != "eli" }) {
      return other.display
    }
    return participants.dropFirst().first?.display ?? labelFallback
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

public struct ImageContent: Equatable, Sendable {
  public let source: String
  public let capturedAt: String?
  public let exifIntact: Bool?
  public let depicts: [String]
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
        corrupt: bool(obj, "corrupt") ?? false)
    }
    return ThreadContent(participants: participants, messages: messages)
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
    let columns = try array(content, "columns").compactMap { value -> String? in
      if case .string(let s) = value { return s }
      return nil
    }
    let rows = try array(content, "rows").map { row -> [JSONValue] in
      if case .array(let cells) = row { return cells }
      throw FragmentContentError.wrongType("rows[]")
    }
    return RecordContent(
      kind: try string(content, "kind"),
      columns: columns,
      rows: rows)
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
    return ImageContent(
      source: try string(content, "source"),
      capturedAt: optionalString(content, "capturedAt"),
      exifIntact: bool(content, "exifIntact"),
      depicts: depicts)
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

  private static func array(_ obj: [String: JSONValue], _ key: String) throws -> [JSONValue] {
    guard let value = obj[key] else { throw FragmentContentError.missingField(key) }
    guard case .array(let arr) = value else { throw FragmentContentError.wrongType(key) }
    return arr
  }
}
