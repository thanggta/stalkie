// Sources/CarveCommerce/CaseProgressStore.swift
// Progress is local and per-case. Revocation never deletes it.

import Foundation
import CarveShell

public enum CaseProgressStore {
  public static func progress(for caseId: String, in directory: URL) -> CaseProgress {
    let store = FileSessionStore(directory: directory, caseId: caseId)
    guard let snapshot = try? store.load() else { return .notStarted }
    if snapshot.isFiled { return .filed }
    if snapshot.carvedIds.isEmpty && snapshot.openedIds.isEmpty && snapshot.draftAnswers.isEmpty {
      return .notStarted
    }
    return .inProgress
  }

  public static func clear(caseId: String, in directory: URL) throws {
    try FileSessionStore(directory: directory, caseId: caseId).clear()
  }

  public static func clearAll(in directory: URL) throws {
    let fm = FileManager.default
    guard let names = try? fm.contentsOfDirectory(atPath: directory.path) else { return }
    for name in names where name.hasPrefix("session_") && name.hasSuffix(".json") {
      try fm.removeItem(at: directory.appendingPathComponent(name))
    }
  }
}
