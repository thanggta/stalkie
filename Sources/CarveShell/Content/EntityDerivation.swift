// Sources/CarveShell/Content/EntityDerivation.swift
// Derive link-board entities from fragment content. No separate entity table.

import Foundation
import CarveCore

public struct BoardEntity: Equatable, Sendable, Identifiable, Hashable {
  public var id: String { entityId }
  public let entityId: String
  /// Best display label found in content (participant display, else humanized id).
  public let displayName: String

  public init(entityId: String, displayName: String) {
    self.entityId = entityId
    self.displayName = displayName
  }
}

public enum EntityDerivation {
  /// Entities the player has actually seen — derived from **carved** fragments only.
  public static func entities(from caseFile: CaseFile, carvedIds: Set<String>) -> [BoardEntity] {
    var displayById: [String: String] = [:]
    var order: [String] = []

    for fragmentId in carvedIds.sorted() {
      guard let fragment = caseFile.fragments[fragmentId] else { continue }
      switch fragment.type {
      case .thread:
        if let content = try? FragmentContent.thread(fragment) {
          for participant in content.participants {
            insert(
              participant.entityId,
              preferredDisplay: participant.display,
              displayById: &displayById,
              order: &order)
          }
        }
      case .image:
        if let content = try? FragmentContent.image(fragment) {
          for entityId in content.depicts {
            insert(
              entityId,
              preferredDisplay: nil,
              displayById: &displayById,
              order: &order)
          }
          if let author = content.authorEntityId {
            insert(
              author,
              preferredDisplay: content.handle,
              displayById: &displayById,
              order: &order)
          }
        }
      case .record:
        if fragment.recordKind == "social_profile",
          let profile = try? FragmentContent.socialProfile(fragment)
        {
          insert(
            profile.entityId,
            preferredDisplay: profile.displayName,
            displayById: &displayById,
            order: &order)
        } else if let content = try? FragmentContent.record(fragment) {
          harvestRecord(content, displayById: &displayById, order: &order)
        }
      case .note, .audio:
        break
      }
    }

    return order.map { id in
      BoardEntity(entityId: id, displayName: displayById[id] ?? humanize(id))
    }
  }

  private static func harvestRecord(
    _ content: RecordContent,
    displayById: inout [String: String],
    order: inout [String]
  ) {
    guard let entityCol = content.columns.firstIndex(of: "entityId") else { return }
    for row in content.rows {
      guard entityCol < row.count else { continue }
      if case .string(let entityId) = row[entityCol], !entityId.isEmpty {
        insert(
          entityId,
          preferredDisplay: nil,
          displayById: &displayById,
          order: &order)
      }
    }
  }

  private static func insert(
    _ entityId: String,
    preferredDisplay: String?,
    displayById: inout [String: String],
    order: inout [String]
  ) {
    if displayById[entityId] == nil {
      order.append(entityId)
      if let preferredDisplay, !preferredDisplay.isEmpty {
        displayById[entityId] = preferredDisplay
      } else {
        displayById[entityId] = humanize(entityId)
      }
    } else if let preferredDisplay, !preferredDisplay.isEmpty {
      // Prefer a real participant display over a humanized id.
      let current = displayById[entityId] ?? ""
      if current == humanize(entityId) {
        displayById[entityId] = preferredDisplay
      }
    }
  }

  private static func humanize(_ entityId: String) -> String {
    entityId
      .split(separator: "_")
      .map { part in
        guard let first = part.first else { return String(part) }
        return String(first).uppercased() + part.dropFirst()
      }
      .joined(separator: " ")
  }
}
