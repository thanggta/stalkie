// Sources/CarveShell/Bundle/CaseLaunch.swift
// Generic case selection. Production default is configuration; play never
// hardcodes a case id in views or routing.

import Foundation

public enum CaseLaunch {
  public static let productionDefault = "five_minutes"
  public static let caseIdFlag = "-caseId"
  public static let pickerFlag = "-showCasePicker"

  public static func resolvedCaseId(
    arguments: [String],
    default defaultId: String = productionDefault
  ) -> String {
    guard let idx = arguments.firstIndex(of: caseIdFlag),
      arguments.indices.contains(idx + 1)
    else {
      return defaultId
    }
    let value = arguments[idx + 1]
    if value.hasPrefix("-") || value.isEmpty {
      return defaultId
    }
    return value
  }

  public static func shouldShowPicker(arguments: [String]) -> Bool {
    arguments.contains(pickerFlag)
  }

  public static func discoverCaseIds(in casesRoot: URL) -> [String] {
    let fm = FileManager.default
    guard let names = try? fm.contentsOfDirectory(atPath: casesRoot.path) else {
      return []
    }
    return names.sorted().filter { name in
      let manifest = casesRoot
        .appendingPathComponent(name, isDirectory: true)
        .appendingPathComponent("case.json")
      return fm.fileExists(atPath: manifest.path)
    }
  }

  /// Bundled `Cases/` first, then repo-relative `cases/` (dev / tests).
  public static func discoverBundledCaseIds(
    bundle: Bundle = .main,
    fileManager: FileManager = .default
  ) -> [String] {
    var seen = Set<String>()
    var ids: [String] = []

    func absorb(_ root: URL) {
      for id in discoverCaseIds(in: root) where !seen.contains(id) {
        seen.insert(id)
        ids.append(id)
      }
    }

    if let bundled = bundle.resourceURL?.appendingPathComponent("Cases", isDirectory: true) {
      absorb(bundled)
    }
    var dir = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    for _ in 0..<6 {
      let candidate = dir.appendingPathComponent("cases", isDirectory: true)
      if fileManager.fileExists(atPath: candidate.path) {
        absorb(candidate)
        break
      }
      dir = dir.deletingLastPathComponent()
    }
    return ids
  }
}
