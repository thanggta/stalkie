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
  case board

  public var title: String {
    PhoneAppLabels.title(for: self)
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

/// Single config for in-game app display names (DR-12 retreat path).
public enum PhoneAppLabels {
  public static func title(for app: PhoneAppId) -> String {
    switch app {
    case .messages: return "Messages"
    case .notes: return "Notes"
    case .phone: return "Phone"
    case .photos: return "Photos"
    case .places: return "Places"
    case .board: return "Links"
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
  /// Draft answers before filing. Keys are question ids.
  @Published public private(set) var draftAnswers: [String: String] = [:]
  /// Set once `fileVerdict` accepts a complete answer set.
  @Published public private(set) var filedReport: VerdictReport?
  @Published public private(set) var isFiled: Bool = false

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

  /// Entities known from carved fragment content (link board input).
  public var boardEntities: [BoardEntity] {
    EntityDerivation.entities(from: caseFile, carvedIds: engine.carvedIds)
  }

  public var linkedPairs: Set<String> {
    engine.state.linkedPairs
  }

  public func hasLink(_ a: String, _ b: String) -> Bool {
    engine.state.hasLink(a, b)
  }

  /// Draw a connection on the board. Canonical key is owned by CarveEngine.
  public func link(_ a: String, _ b: String) {
    guard a != b else { return }
    if engine.state.hasLink(a, b) { return }

    let before = visibleIdSet()
    var next = engine
    next.link(a, b)
    engine = next
    recordUnlocks(before: before, excluding: nil)
  }

  /// Open a fragment: carve if needed, clear its unread state, return outcome.
  @discardableResult
  public func openFragment(_ fragmentId: String) -> CarveResult {
    let before = visibleIdSet()

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
    recordUnlocks(before: before, excluding: fragmentId)
    return result
  }

  /// Record a draft answer and mark the question answered in engine state.
  public func setAnswer(questionId: String, option: String) {
    guard !isFiled else { return }
    guard caseFile.questions.contains(where: { $0.id == questionId }) else { return }
    draftAnswers[questionId] = option
    var next = engine
    next.markAnswered(questionId)
    engine = next
  }

  public var answeredCount: Int {
    caseFile.questions.filter { q in
      guard let a = draftAnswers[q.id] else { return false }
      return !a.isEmpty
    }.count
  }

  public var allQuestionsAnswered: Bool {
    answeredCount == caseFile.questions.count
  }

  /// File the verdict through the same gate the pure engine exposes.
  @discardableResult
  public func fileVerdict() -> FileVerdictResult {
    guard !isFiled else {
      if let report = filedReport {
        return .filed(report)
      }
      return .incomplete(missingQuestionIds: [])
    }
    let result = CarveCore.fileVerdict(caseFile, draftAnswers)
    if case .filed(let report) = result {
      filedReport = report
      isFiled = true
    }
    return result
  }

  /// Fragments the player never opened — replay driver after the verdict.
  public var missedFragments: [Fragment] {
    caseFile.fragments.values
      .filter { !openedIds.contains($0.id) }
      .sorted { $0.label < $1.label }
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

  private func visibleIdSet() -> Set<String> {
    Set(caseFile.fragments.keys.filter { engine.isVisible($0) })
  }

  private func recordUnlocks(before: Set<String>, excluding: String?) {
    let after = visibleIdSet()
    let newlyVisible = after.subtracting(before)
    for id in newlyVisible.sorted() {
      guard let fragment = caseFile.fragments[id] else { continue }
      if id == excluding { continue }
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
  }

  private func recordKind(of fragment: Fragment) -> String? {
    guard fragment.type == .record else { return nil }
    if case .string(let kind) = fragment.content["kind"] { return kind }
    return nil
  }
}
