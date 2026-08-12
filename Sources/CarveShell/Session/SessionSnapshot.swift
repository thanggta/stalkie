// Sources/CarveShell/Session/SessionSnapshot.swift
// Versioned progress blob. IO lives here / app layer — never in CarveCore.

import Foundation
import CarveCore

/// Persisted play state. Compatible restore requires matching case id,
/// case schemaVersion, and snapshotVersion.
public struct SessionSnapshot: Codable, Equatable, Sendable {
  public static let currentVersion = 1

  public let snapshotVersion: Int
  public let caseId: String
  public let schemaVersion: Int
  public let carvedIds: [String]
  public let linkedPairs: [String]
  public let answeredQuestionIds: [String]
  public let openedIds: [String]
  public let unreadUnlockIds: [String]
  public let draftAnswers: [String: String]
  public let filedReport: VerdictReport?
  public let isFiled: Bool
  public let themeId: String

  public init(
    snapshotVersion: Int = SessionSnapshot.currentVersion,
    caseId: String,
    schemaVersion: Int,
    carvedIds: [String],
    linkedPairs: [String],
    answeredQuestionIds: [String],
    openedIds: [String],
    unreadUnlockIds: [String],
    draftAnswers: [String: String],
    filedReport: VerdictReport?,
    isFiled: Bool,
    themeId: String
  ) {
    self.snapshotVersion = snapshotVersion
    self.caseId = caseId
    self.schemaVersion = schemaVersion
    self.carvedIds = carvedIds
    self.linkedPairs = linkedPairs
    self.answeredQuestionIds = answeredQuestionIds
    self.openedIds = openedIds
    self.unreadUnlockIds = unreadUnlockIds
    self.draftAnswers = draftAnswers
    self.filedReport = filedReport
    self.isFiled = isFiled
    self.themeId = themeId
  }
}

public enum SessionPersistenceError: Error, Equatable, CustomStringConvertible {
  case corrupt(String)
  case snapshotVersionMismatch(found: Int, expected: Int)
  case schemaMismatch(snapshot: Int, caseSchema: Int)
  case caseMismatch(snapshotCase: String, loadedCase: String)
  case emptyCase

  public var description: String {
    switch self {
    case .corrupt(let detail):
      return "Saved progress is unreadable: \(detail)"
    case .snapshotVersionMismatch(let found, let expected):
      return "Saved progress version \(found) is incompatible (need \(expected))."
    case .schemaMismatch(let snapshot, let caseSchema):
      return "Saved progress schema \(snapshot) does not match case schema \(caseSchema)."
    case .caseMismatch(let snapshotCase, let loadedCase):
      return "Saved progress is for \"\(snapshotCase)\" but loaded \"\(loadedCase)\"."
    case .emptyCase:
      return "Refusing to start with an empty fabricated case."
    }
  }
}

/// Read/write session snapshots. Implementations may use disk or memory.
public protocol SessionStore: AnyObject {
  func load() throws -> SessionSnapshot?
  func save(_ snapshot: SessionSnapshot) throws
  func clear() throws
}

/// File-backed store under a directory the app owns.
public final class FileSessionStore: SessionStore {
  public let fileURL: URL
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()

  public init(directory: URL, fileName: String = "session_snapshot_v1.json") {
    self.fileURL = directory.appendingPathComponent(fileName)
  }

  public convenience init(fileURL: URL) {
    self.init(directory: fileURL.deletingLastPathComponent(), fileName: fileURL.lastPathComponent)
  }

  public func load() throws -> SessionSnapshot? {
    let fm = FileManager.default
    guard fm.fileExists(atPath: fileURL.path) else { return nil }
    let data: Data
    do {
      data = try Data(contentsOf: fileURL)
    } catch {
      throw SessionPersistenceError.corrupt("could not read snapshot file")
    }
    guard !data.isEmpty else {
      throw SessionPersistenceError.corrupt("snapshot file is empty")
    }
    do {
      return try decoder.decode(SessionSnapshot.self, from: data)
    } catch {
      throw SessionPersistenceError.corrupt(String(describing: error))
    }
  }

  public func save(_ snapshot: SessionSnapshot) throws {
    let dir = fileURL.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let data = try encoder.encode(snapshot)
    try data.write(to: fileURL, options: .atomic)
  }

  public func clear() throws {
    let fm = FileManager.default
    if fm.fileExists(atPath: fileURL.path) {
      try fm.removeItem(at: fileURL)
    }
  }
}

/// In-memory store for tests.
public final class MemorySessionStore: SessionStore {
  public private(set) var snapshot: SessionSnapshot?

  public init(snapshot: SessionSnapshot? = nil) {
    self.snapshot = snapshot
  }

  public func load() throws -> SessionSnapshot? { snapshot }

  public func save(_ snapshot: SessionSnapshot) throws {
    self.snapshot = snapshot
  }

  public func clear() throws {
    snapshot = nil
  }
}
