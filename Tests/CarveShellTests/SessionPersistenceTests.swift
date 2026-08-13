// Tests/CarveShellTests/SessionPersistenceTests.swift
// Why: process death must not erase progress. Round-trip and failure modes
// are the product contract for free-browsing sessions.

import Foundation
import Testing
@testable import CarveCore
@testable import CarveShell

private func loadFiveMinutes() throws -> CaseFile {
  let dir = "cases/five_minutes"
  let manifestData = try #require(
    FileManager.default.contents(atPath: "\(dir)/case.json"),
    "case.json not found — run `swift test` from the package root")
  var fragmentFiles: [(name: String, data: Data)] = []
  let fragmentsDir = "\(dir)/fragments"
  let names = try FileManager.default.contentsOfDirectory(atPath: fragmentsDir)
  for name in names.sorted() where name.hasSuffix(".json") {
    if let data = FileManager.default.contents(atPath: "\(fragmentsDir)/\(name)") {
      fragmentFiles.append((name: name, data: data))
    }
  }
  return try parseCase(manifestData: manifestData, fragmentFiles: fragmentFiles)
}

struct SessionPersistenceTests {
  @Test func snapshotRoundTripsAllMeaningfulState() throws {
    let caseFile = try loadFiveMinutes()
    let session = GameSession(caseFile: caseFile, themeId: Theme.fallbackWorkstation.id)

    #expect(session.openFragment("thread_theo").outcome == .ok)
    #expect(session.openFragment("thread_sable").outcome == .ok)
    session.link("eli", "sable")
    #expect(session.isVisible("record_places"))
    #expect(session.openFragment("record_places").outcome == .ok)

    session.setAnswer(questionId: "q_sable_who", option: "affair")
    session.setTheme(Theme.iosLookalike.id)

    let store = MemorySessionStore()
    try store.save(session.makeSnapshot())

    let loaded = try store.load()
    let restored = try GameSession(caseFile: caseFile, snapshot: try #require(loaded))
    #expect(restored.engine.carvedIds.contains("thread_theo"))
    #expect(restored.engine.carvedIds.contains("thread_sable"))
    #expect(restored.engine.carvedIds.contains("record_places"))
    #expect(restored.hasLink("eli", "sable"))
    #expect(restored.isVisible("record_places"))
    #expect(restored.openedIds.contains("record_places"))
    #expect(restored.draftAnswers["q_sable_who"] == "affair")
    #expect(restored.themeId == Theme.iosLookalike.id)
    #expect(restored.isFiled == false)
  }

  @Test func restoredLinkedPairKeepsLinkedGatedContentVisible() throws {
    let caseFile = try loadFiveMinutes()
    let session = GameSession(caseFile: caseFile)
    #expect(session.openFragment("thread_theo").outcome == .ok)
    #expect(session.openFragment("thread_sable").outcome == .ok)
    session.link("eli", "sable")
    #expect(session.isVisible("record_places"))

    let snapshot = session.makeSnapshot()
    let restored = try GameSession(caseFile: caseFile, snapshot: snapshot)
    #expect(restored.isVisible("record_places"))
    #expect(restored.visibleFragments(in: .places).contains { $0.id == "record_places" })
  }

  @Test func filedStateRoundTrips() throws {
    let caseFile = try loadFiveMinutes()
    let session = GameSession(caseFile: caseFile)
    for q in caseFile.questions {
      session.setAnswer(questionId: q.id, option: q.correct)
    }
    let result = session.fileVerdict()
    guard case .filed = result else {
      Issue.record("expected filed verdict")
      return
    }
    #expect(session.isFiled)

    let restored = try GameSession(caseFile: caseFile, snapshot: session.makeSnapshot())
    #expect(restored.isFiled)
    #expect(restored.filedReport?.total == caseFile.questions.count)
    #expect(restored.filedReport?.correct == caseFile.questions.count)
  }

  @Test func corruptSnapshotFailsVisibly() throws {
    let dir = FileManager.default.temporaryDirectory
      .appendingPathComponent("carve-persist-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }

    let store = FileSessionStore(directory: dir)
    try Data("{not json".utf8).write(to: store.fileURL)

    do {
      _ = try store.load()
      Issue.record("corrupt load should throw")
    } catch let error as SessionPersistenceError {
      guard case .corrupt = error else {
        Issue.record("expected corrupt, got \(error)")
        return
      }
    }
  }

  @Test func versionMismatchFailsOnRestore() throws {
    let caseFile = try loadFiveMinutes()
    let session = GameSession(caseFile: caseFile)
    let snapshot = session.makeSnapshot()
    // Force incompatible version via encode/decode patch.
    let encoder = JSONEncoder()
    var obj = try JSONSerialization.jsonObject(with: encoder.encode(snapshot)) as! [String: Any]
    obj["snapshotVersion"] = 999
    let data = try JSONSerialization.data(withJSONObject: obj)
    let bad = try JSONDecoder().decode(SessionSnapshot.self, from: data)

    do {
      _ = try GameSession(caseFile: caseFile, snapshot: bad)
      Issue.record("version mismatch should throw")
    } catch let error as SessionPersistenceError {
      guard case .snapshotVersionMismatch = error else {
        Issue.record("expected snapshotVersionMismatch, got \(error)")
        return
      }
    }
  }

  @Test func caseMismatchFailsOnRestore() throws {
    let caseFile = try loadFiveMinutes()
    let session = GameSession(caseFile: caseFile)
    let encoder = JSONEncoder()
    var obj = try JSONSerialization.jsonObject(with: encoder.encode(session.makeSnapshot()))
      as! [String: Any]
    obj["caseId"] = "other_case"
    let bad = try JSONDecoder().decode(
      SessionSnapshot.self, from: try JSONSerialization.data(withJSONObject: obj))

    do {
      _ = try GameSession(caseFile: caseFile, snapshot: bad)
      Issue.record("case mismatch should throw")
    } catch let error as SessionPersistenceError {
      guard case .caseMismatch = error else {
        Issue.record("expected caseMismatch, got \(error)")
        return
      }
    }
  }

  @Test func mutationCallbackSavesSnapshot() throws {
    let caseFile = try loadFiveMinutes()
    let store = MemorySessionStore()
    let session = GameSession(caseFile: caseFile)
    SessionPersistence.attach(store: store, to: session)
    #expect(session.openFragment("thread_theo").outcome == .ok)
    let saved = try #require(try store.load())
    #expect(saved.carvedIds.contains("thread_theo"))
    #expect(session.persistenceFailure == nil)
  }

  /// Why: AppBootstrap holds only the session after `load` returns. If attach
  /// weak-captures the store, every carve/link/file silently no-ops and the
  /// free full-loop relaunch cannot restore Decide / filed results.
  @Test func attachKeepsStoreAliveAfterCallerReleasesIt() throws {
    let caseFile = try loadFiveMinutes()
    let session = GameSession(caseFile: caseFile)
    weak var weakStore: MemorySessionStore?

    do {
      let store = MemorySessionStore()
      weakStore = store
      SessionPersistence.attach(store: store, to: session)
    }

    #expect(weakStore != nil, "attach must retain the store for the session lifetime")
    #expect(session.openFragment("thread_theo").outcome == .ok)
    #expect(session.openFragment("thread_sable").outcome == .ok)
    let saved = try #require(try weakStore?.load())
    #expect(saved.carvedIds.contains("thread_sable"))
  }

  /// Why: after filing, relaunch must show Decide so results are reachable.
  /// A snapshot with isFiled + carved thread_sable is the free-case contract.
  @Test func filedRestoreKeepsDecideVisible() throws {
    let caseFile = try loadFiveMinutes()
    let session = GameSession(caseFile: caseFile)
    #expect(session.isDecideVisible == false)

    #expect(session.openFragment("thread_theo").outcome == .ok)
    #expect(session.isDecideVisible == false)
    #expect(session.openFragment("thread_sable").outcome == .ok)
    #expect(session.isDecideVisible == true)

    for q in caseFile.questions {
      session.setAnswer(questionId: q.id, option: q.correct)
    }
    guard case .filed = session.fileVerdict() else {
      Issue.record("expected filed verdict")
      return
    }

    let restored = try GameSession(caseFile: caseFile, snapshot: session.makeSnapshot())
    #expect(restored.isFiled)
    #expect(restored.engine.carvedIds.contains("thread_sable"))
    #expect(restored.isDecideVisible == true)
  }

  @Test func saveFailureIsVisibleAndDoesNotReportSuccess() throws {
    // A disk write that throws must not look like progress was saved.
    // The player gets a recovery warning; the developer error is preserved; retry works.
    let caseFile = try loadFiveMinutes()
    let store = ThrowingSessionStore(error: TestSaveError.diskFull)
    let session = GameSession(caseFile: caseFile)
    SessionPersistence.attach(store: store, to: session)

    #expect(session.openFragment("thread_theo").outcome == .ok)
    #expect(session.engine.carvedIds.contains("thread_theo"))

    let failure = try #require(session.persistenceFailure)
    #expect(store.savedSnapshots.isEmpty, "a throwing store must not be treated as saved")
    #expect(failure.playerMessage == PlayerFacingCopy.saveFailed)
    #expect(failure.developerDetail.contains("diskFull"))
    #expect(PlayerFacingCopy.containsEngineVocabulary(failure.playerMessage) == false)

    store.error = nil
    session.retryPersistence()

    #expect(session.persistenceFailure == nil)
    #expect(store.savedSnapshots.count == 1)
    #expect(store.savedSnapshots[0].carvedIds.contains("thread_theo"))
  }

  @Test func fileStoreRoundTrip() throws {
    let caseFile = try loadFiveMinutes()
    let dir = FileManager.default.temporaryDirectory
      .appendingPathComponent("carve-file-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }

    let store = FileSessionStore(directory: dir)
    let session = GameSession(caseFile: caseFile)
    #expect(session.openFragment("thread_theo").outcome == .ok)
    try store.save(session.makeSnapshot())
    try store.clear()
    #expect(try store.load() == nil)
  }
}

private enum TestSaveError: Error, CustomStringConvertible {
  case diskFull
  var description: String { "diskFull" }
}

/// Store that can be told to throw on save so the session boundary is testable.
private final class ThrowingSessionStore: SessionStore {
  var error: Error?
  private(set) var savedSnapshots: [SessionSnapshot] = []

  init(error: Error?) {
    self.error = error
  }

  func load() throws -> SessionSnapshot? { savedSnapshots.last }

  func save(_ snapshot: SessionSnapshot) throws {
    if let error {
      throw error
    }
    savedSnapshots.append(snapshot)
  }

  func clear() throws {
    savedSnapshots.removeAll()
  }
}
