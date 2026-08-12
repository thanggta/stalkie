// Sources/CarveShell/Session/GameSession.swift
// Observable shell state over pure CarveEngine. Views never call engine
// rules directly beyond what this type exposes — keeps game logic out of UI.

import Combine
import Foundation
import CarveCore

/// Something that just became visible because the player carved elsewhere.
/// Surfaced so unlocks are legible (compliance §3 / first-two-minutes bar).
public struct UnlockNotice: Equatable, Sendable, Identifiable {
  public var id: String { fragmentId }
  public let fragmentId: String
  public let label: String
  public let type: FragmentType
  public let appId: PhoneAppId
}

/// Home-screen / in-app destinations.
///
/// Display names are NOT declared here. Per DR-12 in-game apps carry real platform brands, and
/// every brand string must live in one config file so reverting to invented names is a config
/// edit rather than a rewrite — that is DR-12's only retreat path. Add the case here, the label
/// there.
public enum PhoneAppId: String, CaseIterable, Sendable, Equatable {
  case messages
  case notes
  case phone
  case photos
  case places

  public var title: String {
    switch self {
    case .messages: return "Messages"
    case .notes: return "Notes"
    case .phone: return "Phone"
    case .photos: return "Photos"
    case .places: return "Places"
    }
  }

  public static func hosting(type: FragmentType, recordKind: String? = nil) -> PhoneAppId {
    switch type {
    case .thread: return .messages
    case .note: return .notes
    case .image: return .photos
    case .record:
      if recordKind == "location" { return .places }
      return .phone
    case .audio: return .phone
    }
  }
}

public struct VisibleFragmentItem: Equatable, Sendable, Identifiable {
  public var id: String { fragment.id }
  public let fragment: Fragment
  public let isCarved: Bool
  public let isUnreadUnlock: Bool
  public let appId: PhoneAppId
}

/// Shell session: loads a case, carves on open, tracks unlock notices.
public final class GameSession: ObservableObject {
  public let caseFile: CaseFile
  @Published public private(set) var engine: CarveEngine
  /// Fragment ids the player has opened at least once (for unread-unlock UI).
  @Published public private(set) var openedIds: Set<String> = []
  /// Notices not yet dismissed by the player.
  @Published public private(set) var pendingNotices: [UnlockNotice] = []
  /// Ids that appeared via unlock and have not been opened yet — drives badges.
  @Published public private(set) var unreadUnlockIds: Set<String> = []
  @Published public var themeId: String

  public init(caseFile: CaseFile, themeId: String = Theme.iosLookalike.id) {
    self.caseFile = caseFile
    self.engine = CarveEngine(caseFile: caseFile)
    self.themeId = themeId
  }

  public var theme: Theme { Theme.builtIn(id: themeId) }

  public func setTheme(_ id: String) {
    themeId = id
  }

  public var visibleFragments: [VisibleFragmentItem] {
    caseFile.fragments.values
      .filter { engine.isVisible($0.id) }
      .sorted { $0.label < $1.label }
      .map { fragment in
        let kind = recordKind(of: fragment)
        return VisibleFragmentItem(
          fragment: fragment,
          isCarved: engine.carvedIds.contains(fragment.id),
          isUnreadUnlock: unreadUnlockIds.contains(fragment.id),
          appId: PhoneAppId.hosting(type: fragment.type, recordKind: kind))
      }
  }

  public func visibleFragments(in app: PhoneAppId) -> [VisibleFragmentItem] {
    visibleFragments.filter { $0.appId == app }
  }

  public func badgeCount(for app: PhoneAppId) -> Int {
    unreadUnlockIds.filter { id in
      guard let fragment = caseFile.fragments[id] else { return false }
      return PhoneAppId.hosting(type: fragment.type, recordKind: recordKind(of: fragment)) == app
    }.count
  }

  /// Open a fragment: carve if needed, clear its unread state, return outcome.
  @discardableResult
  public func openFragment(_ fragmentId: String) -> CarveResult {
    let before = Set(caseFile.fragments.keys.filter { engine.isVisible($0) })

    // Mutate a local copy then reassign so @Published fires (struct property).
    var next = engine
    let result: CarveResult
    if next.carvedIds.contains(fragmentId) {
      result = CarveResult(
        outcome: .alreadyCarved,
        fragment: caseFile.fragments[fragmentId])
    } else {
      result = next.carve(fragmentId)
    }

    guard result.outcome == .ok || result.outcome == .alreadyCarved else {
      return result
    }

    engine = next
    openedIds.insert(fragmentId)
    unreadUnlockIds.remove(fragmentId)

    let after = Set(caseFile.fragments.keys.filter { engine.isVisible($0) })
    let newlyVisible = after.subtracting(before)
    for id in newlyVisible.sorted() {
      guard let fragment = caseFile.fragments[id] else { continue }
      // The fragment just opened is not an "unlock notice" for itself.
      if id == fragmentId { continue }
      unreadUnlockIds.insert(id)
      let kind = recordKind(of: fragment)
      let notice = UnlockNotice(
        fragmentId: id,
        label: fragment.label,
        type: fragment.type,
        appId: PhoneAppId.hosting(type: fragment.type, recordKind: kind))
      if !pendingNotices.contains(where: { $0.fragmentId == id }) {
        pendingNotices.append(notice)
      }
    }
    return result
  }

  public func dismissNotice(_ fragmentId: String) {
    pendingNotices.removeAll { $0.fragmentId == fragmentId }
  }

  public func dismissAllNotices() {
    pendingNotices.removeAll()
  }

  public func isVisible(_ fragmentId: String) -> Bool {
    engine.isVisible(fragmentId)
  }

  private func recordKind(of fragment: Fragment) -> String? {
    guard fragment.type == .record else { return nil }
    if case .string(let kind) = fragment.content["kind"] { return kind }
    return nil
  }
}
