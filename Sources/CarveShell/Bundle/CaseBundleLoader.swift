// Sources/CarveShell/Bundle/CaseBundleLoader.swift
// Loads a case directory from disk or from an app bundle resource.

import Foundation
import CarveCore

public enum CaseBundleLoaderError: Error, Equatable, CustomStringConvertible {
  case missingManifest(String)
  case missingFragmentsDir(String)
  case emptyFragments(String)
  case parse(String)

  public var description: String {
    switch self {
    case .missingManifest(let p): return "Missing case.json at \(p)"
    case .missingFragmentsDir(let p): return "Missing fragments/ at \(p)"
    case .emptyFragments(let p): return "No fragment files in \(p)"
    case .parse(let m): return m
    }
  }
}

public enum CaseBundleLoader {
  /// Load from a filesystem directory (`…/five_minutes` containing case.json).
  public static func load(directory: URL) throws -> CaseFile {
    let manifestURL = directory.appendingPathComponent("case.json")
    guard let manifestData = try? Data(contentsOf: manifestURL) else {
      throw CaseBundleLoaderError.missingManifest(manifestURL.path)
    }
    let fragmentsDir = directory.appendingPathComponent("fragments")
    guard let names = try? FileManager.default.contentsOfDirectory(atPath: fragmentsDir.path)
    else {
      throw CaseBundleLoaderError.missingFragmentsDir(fragmentsDir.path)
    }
    var fragmentFiles: [(name: String, data: Data)] = []
    for name in names.sorted() where name.hasSuffix(".json") {
      let url = fragmentsDir.appendingPathComponent(name)
      if let data = try? Data(contentsOf: url) {
        fragmentFiles.append((name: name, data: data))
      }
    }
    if fragmentFiles.isEmpty {
      throw CaseBundleLoaderError.emptyFragments(fragmentsDir.path)
    }
    do {
      return try parseCase(manifestData: manifestData, fragmentFiles: fragmentFiles)
    } catch let error as CaseFormatError {
      throw CaseBundleLoaderError.parse(error.message)
    } catch {
      throw CaseBundleLoaderError.parse(String(describing: error))
    }
  }

  /// Resolve media file relative to the case directory.
  public static func mediaURL(caseDirectory: URL, source: String) -> URL {
    caseDirectory.appendingPathComponent(source)
  }

  /// Prefer bundled resource `Cases/<id>`, then repo-relative `cases/<id>` (tests/dev).
  public static func resolveCaseDirectory(
    id: String,
    bundle: Bundle = .main,
    fileManager: FileManager = .default
  ) -> URL? {
    if let bundled = bundle.resourceURL?
      .appendingPathComponent("Cases", isDirectory: true)
      .appendingPathComponent(id, isDirectory: true),
      fileManager.fileExists(atPath: bundled.appendingPathComponent("case.json").path)
    {
      return bundled
    }
    // Xcode folder-reference layout: Cases/five_minutes at bundle root
    if let bundled = bundle.resourceURL?
      .appendingPathComponent(id, isDirectory: true),
      fileManager.fileExists(atPath: bundled.appendingPathComponent("case.json").path)
    {
      return bundled
    }
    // Dev / test: cwd or ancestors containing cases/<id>
    var dir = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    for _ in 0..<6 {
      let candidate = dir.appendingPathComponent("cases").appendingPathComponent(id)
      if fileManager.fileExists(atPath: candidate.appendingPathComponent("case.json").path) {
        return candidate
      }
      dir = dir.deletingLastPathComponent()
    }
    return nil
  }
}
