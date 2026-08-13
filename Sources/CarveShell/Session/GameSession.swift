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
///
/// Content routing uses `ContentSurface` (DR-13), not fragment ids or brand strings.
public enum PhoneAppId: String, CaseIterable, Sendable, Equatable {
  // Case content apps
  case messages
  case notes
  case phone
  case photos
  case places
  case photoSocial = "photo_social"
  case ephemeralChat = "ephemeral_chat"
  case board
  case decide
  // Shell fillers — real phones are dense; these open empty diegetic shells.
  case calendar
  case camera
  case browser
  case mail
  case settings
  case music
  case clock
  case reminders
  case weather
  case facetime
  case appstore
  case health
  case wallet
  case files
  case books
  case podcasts
  case tv
  case homekit
  case contacts
  case calculator
  case stocks

  public var title: String {
    PhoneAppLabels.title(for: self)
  }

  /// Apps that carry case fragments / game systems.
  public var isGameApp: Bool {
    switch self {
    case .messages, .notes, .phone, .photos, .places, .photoSocial, .ephemeralChat, .board, .decide:
      return true
    case .calendar, .camera, .browser, .mail, .settings, .music, .clock, .reminders,
      .weather, .facetime, .appstore, .health, .wallet, .files, .books,
      .podcasts, .tv, .homekit, .contacts, .calculator, .stocks:
      return false
    }
  }

  /// Map declarative surface → home-screen app. Brand strings stay in PhoneAppLabels.
  public static func hosting(surface: ContentSurface) -> PhoneAppId {
    switch surface {
    case .messages: return .messages
    case .notes: return .notes
    case .photos: return .photos
    case .phone: return .phone
    case .maps: return .places
    case .photoSocial: return .photoSocial
    case .ephemeralChat: return .ephemeralChat
    }
  }

  /// Legacy helper — prefer `hosting(surface:)` once surface is known.
  public static func hosting(type: FragmentType, recordKind: String? = nil) -> PhoneAppId {
    hosting(surface: ContentSurface.defaultSurface(for: type, recordKind: recordKind))
  }

  public static func hosting(fragment: Fragment) -> PhoneAppId {
    hosting(surface: fragment.surface)
  }
}

/// Single config for in-game app display names (DR-12 retreat path).
/// Real platform brands live ONLY here — never in case JSON or views.
public enum PhoneAppLabels {
  public static func title(for app: PhoneAppId) -> String {
    switch app {
    case .messages: return "Messages"
    case .notes: return "Notes"
    case .phone: return "Phone"
    case .photos: return "Photos"
    case .places: return "Google Maps"
    case .photoSocial: return "Instagram"
    case .ephemeralChat: return "Snapchat"
    case .board: return "Links"
    case .decide: return "Decide"
    case .calendar: return "Calendar"
    case .camera: return "Camera"
    case .browser: return "Safari"
    case .mail: return "Mail"
    case .settings: return "Settings"
    case .music: return "Music"
    case .clock: return "Clock"
    case .reminders: return "Reminders"
    case .weather: return "Weather"
    case .facetime: return "FaceTime"
    case .appstore: return "App Store"
    case .health: return "Health"
    case .wallet: return "Wallet"
    case .files: return "Files"
    case .books: return "Books"
    case .podcasts: return "Podcasts"
    case .tv: return "TV"
    case .homekit: return "Home"
    case .contacts: return "Contacts"
    case .calculator: return "Calculator"
    case .stocks: return "Stocks"
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
  /// Last failed save. Nil means the most recent persist succeeded or was never attempted.
  @Published public private(set) var persistenceFailure: PersistenceFailure?
  /// Called after every meaningful mutation so the app can persist.
  public var onMutation: ((GameSession) -> Void)?

  public init(caseFile: CaseFile, themeId: String = Theme.iosLookalike.id) {
    self.caseFile = caseFile
    self.engine = CarveEngine(caseFile: caseFile)
    self.themeId = themeId
  }

  /// Restore shell + engine progress from a compatible snapshot.
  public init(caseFile: CaseFile, snapshot: SessionSnapshot) throws {
    guard snapshot.caseId == caseFile.id else {
      throw SessionPersistenceError.caseMismatch(
        snapshotCase: snapshot.caseId, loadedCase: caseFile.id)
    }
    guard snapshot.schemaVersion == caseFile.schemaVersion else {
      throw SessionPersistenceError.schemaMismatch(
        snapshot: snapshot.schemaVersion, caseSchema: caseFile.schemaVersion)
    }
    guard snapshot.snapshotVersion == SessionSnapshot.currentVersion else {
      throw SessionPersistenceError.snapshotVersionMismatch(
        found: snapshot.snapshotVersion, expected: SessionSnapshot.currentVersion)
    }
    self.caseFile = caseFile
    self.engine = CarveEngine(
      caseFile: caseFile,
      carved: Set(snapshot.carvedIds),
      links: Set(snapshot.linkedPairs),
      answered: Set(snapshot.answeredQuestionIds))
    self.openedIds = Set(snapshot.openedIds)
    self.unreadUnlockIds = Set(snapshot.unreadUnlockIds)
    self.draftAnswers = snapshot.draftAnswers
    self.filedReport = snapshot.filedReport
    self.isFiled = snapshot.isFiled
    self.themeId = snapshot.themeId
    // Rebuild notices for unread unlocks still visible.
    self.pendingNotices = snapshot.unreadUnlockIds.compactMap { id in
      guard let fragment = caseFile.fragments[id], engine.isVisible(id) else { return nil }
      return UnlockNotice(
        fragmentId: id,
        label: fragment.label,
        type: fragment.type,
        appId: PhoneAppId.hosting(fragment: fragment))
    }
  }

  public var theme: Theme { Theme.builtIn(id: themeId) }

  public func setTheme(_ id: String) {
    themeId = id
    persist()
  }

  public var visibleFragments: [VisibleFragmentItem] {
    caseFile.fragments.values
      .filter { engine.isVisible($0.id) }
      .sorted { $0.label < $1.label }
      .map { fragment in
        VisibleFragmentItem(
          fragment: fragment,
          isCarved: engine.carvedIds.contains(fragment.id),
          isUnreadUnlock: unreadUnlockIds.contains(fragment.id),
          appId: PhoneAppId.hosting(fragment: fragment))
      }
  }

  public func visibleFragments(in app: PhoneAppId) -> [VisibleFragmentItem] {
    visibleFragments.filter { $0.appId == app }
  }

  public func badgeCount(for app: PhoneAppId) -> Int {
    unreadUnlockIds.filter { id in
      guard let fragment = caseFile.fragments[id] else { return false }
      return PhoneAppId.hosting(fragment: fragment) == app
    }.count
  }

  /// Versioned snapshot of all progress the player would lose on process death.
  public func makeSnapshot() -> SessionSnapshot {
    SessionSnapshot(
      snapshotVersion: SessionSnapshot.currentVersion,
      caseId: caseFile.id,
      schemaVersion: caseFile.schemaVersion,
      carvedIds: Array(engine.carvedIds).sorted(),
      linkedPairs: Array(engine.state.linkedPairs).sorted(),
      answeredQuestionIds: Array(engine.state.answeredQuestionIds).sorted(),
      openedIds: Array(openedIds).sorted(),
      unreadUnlockIds: Array(unreadUnlockIds).sorted(),
      draftAnswers: draftAnswers,
      filedReport: filedReport,
      isFiled: isFiled,
      themeId: themeId)
  }

  /// Entities known from carved fragment content (link board input).
  public var boardEntities: [BoardEntity] {
    EntityDerivation.entities(from: caseFile, carvedIds: engine.carvedIds)
  }

  public var linkedPairs: Set<String> {
    engine.state.linkedPairs
  }

  /// Links is a phone app only after two named people exist (DR-14).
  public var isLinksVisible: Bool {
    AppReadiness.linksReady(entities: boardEntities)
  }

  /// Decide appears when the case's readiness predicate (or the generic
  /// supporting-fragment default) is true. Once filed it stays visible so the
  /// player can reopen results after a relaunch. Never case-id specific.
  public var isDecideVisible: Bool {
    if isFiled { return true }
    return AppReadiness.decideReady(caseFile: caseFile, state: engine.state)
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
    persist()
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
    persist()
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
    persist()
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
      persist()
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
    persist()
  }

  public func dismissAllNotices() {
    pendingNotices.removeAll()
    persist()
  }

  /// Record a failed save without crashing and without pretending it worked.
  public func recordPersistenceFailure(_ failure: PersistenceFailure) {
    persistenceFailure = failure
  }

  public func clearPersistenceFailure() {
    persistenceFailure = nil
  }

  /// Re-attempt the last persist. The store decides success or failure.
  public func retryPersistence() {
    persist()
  }

  public func isVisible(_ fragmentId: String) -> Bool {
    engine.isVisible(fragmentId)
  }

  private func persist() {
    onMutation?(self)
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
      let notice = UnlockNotice(
        fragmentId: id,
        label: fragment.label,
        type: fragment.type,
        appId: PhoneAppId.hosting(fragment: fragment))
      if !pendingNotices.contains(where: { $0.fragmentId == id }) {
        pendingNotices.append(notice)
      }
    }
  }
}
