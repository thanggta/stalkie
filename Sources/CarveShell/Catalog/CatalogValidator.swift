// Sources/CarveShell/Catalog/CatalogValidator.swift
// Catalog is the only source of library order and access. Available entries
// must resolve to bundled valid cases.

import Foundation
import CarveCore

public struct CatalogValidationContext: Equatable, Sendable {
  public let bundledCaseIds: Set<String>
  public let casesRoot: URL?

  public init(bundledCaseIds: Set<String>, casesRoot: URL? = nil) {
    self.bundledCaseIds = bundledCaseIds
    self.casesRoot = casesRoot
  }
}

/// Empty array means valid.
public func validateCatalog(
  _ catalog: CaseCatalog,
  context: CatalogValidationContext
) -> [String] {
  var problems: [String] = []

  if catalog.schemaVersion != 1 {
    problems.append("Catalog schemaVersion must be 1.")
  }
  if catalog.entries.isEmpty {
    problems.append("Catalog must list at least one case.")
  }

  var seenIds = Set<String>()
  var seenOrders = Set<Int>()
  var seenProducts = Set<String>()
  var freeCount = 0

  for entry in catalog.entries {
    if !seenIds.insert(entry.caseId).inserted {
      problems.append("Duplicate catalog case id \"\(entry.caseId)\".")
    }
    if !seenOrders.insert(entry.order).inserted {
      problems.append("Duplicate catalog order \(entry.order).")
    }

    switch entry.access {
    case .free:
      freeCount += 1
      if entry.productId != nil {
        problems.append(
          "Free catalog entry \"\(entry.caseId)\" cannot carry a productId.")
      }
    case .paid:
      guard let productId = entry.productId, !productId.isEmpty else {
        problems.append(
          "Paid catalog entry \"\(entry.caseId)\" must carry a productId.")
        break
      }
      if !seenProducts.insert(productId).inserted {
        problems.append("Duplicate StoreKit product id \"\(productId)\".")
      }
    }

    if entry.availability == .available {
      if !context.bundledCaseIds.contains(entry.caseId) {
        problems.append(
          "Available catalog entry \"\(entry.caseId)\" does not resolve to a bundled case.")
      }
      if let root = context.casesRoot {
        let artworkURL = root.appendingPathComponent(entry.artwork)
        if !FileManager.default.fileExists(atPath: artworkURL.path) {
          problems.append(
            "Catalog entry \"\(entry.caseId)\" artwork \"\(entry.artwork)\" is missing.")
        }
      }
    }
  }

  if freeCount == 0 {
    problems.append("Catalog must include at least one free case.")
  }

  return problems
}

/// Parse + structural checks + load every available case through the existing validator.
public func validateCatalogBundle(catalogURL: URL, casesRoot: URL) -> [String] {
  let data: Data
  do {
    data = try Data(contentsOf: catalogURL)
  } catch {
    return ["Could not read catalog at \(catalogURL.path)."]
  }

  let catalog: CaseCatalog
  do {
    catalog = try parseCatalog(data: data)
  } catch let error as CatalogFormatError {
    return [error.message]
  } catch {
    return ["catalog.json: \(error)"]
  }

  let bundled = Set(CaseLaunch.discoverCaseIds(in: casesRoot))
  var problems = validateCatalog(
    catalog,
    context: CatalogValidationContext(bundledCaseIds: bundled, casesRoot: casesRoot))

  for entry in catalog.entries where entry.availability == .available {
    let directory = casesRoot.appendingPathComponent(entry.caseId, isDirectory: true)
    do {
      let caseFile = try CaseBundleLoader.load(directory: directory)
      if caseFile.id != entry.caseId {
        problems.append(
          "Catalog entry \"\(entry.caseId)\" resolves to case.json id \"\(caseFile.id)\".")
      }
      problems.append(contentsOf: validateCase(caseFile).map { "\(entry.caseId): \($0)" })
    } catch {
      problems.append("Available catalog entry \"\(entry.caseId)\" failed to load: \(error)")
    }
  }

  return problems
}

public enum CatalogLoader {
  /// Bundled `Cases/catalog.json`, then repo-relative `cases/catalog.json`.
  public static func load(
    bundle: Bundle = .main,
    fileManager: FileManager = .default
  ) throws -> CaseCatalog {
    if let url = resolveCatalogURL(bundle: bundle, fileManager: fileManager) {
      let data = try Data(contentsOf: url)
      return try parseCatalog(data: data)
    }
    throw CatalogFormatError("catalog.json was not found in the bundle or repo cases/.")
  }

  public static func resolveCatalogURL(
    bundle: Bundle = .main,
    fileManager: FileManager = .default
  ) -> URL? {
    let bundledCandidates = [
      bundle.resourceURL?.appendingPathComponent("Cases/catalog.json"),
      bundle.resourceURL?.appendingPathComponent("catalog.json"),
    ]
    for url in bundledCandidates.compactMap({ $0 }) {
      if fileManager.fileExists(atPath: url.path) { return url }
    }
    var dir = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    for _ in 0..<6 {
      let candidate = dir.appendingPathComponent("cases/catalog.json")
      if fileManager.fileExists(atPath: candidate.path) { return candidate }
      dir = dir.deletingLastPathComponent()
    }
    return nil
  }

  public static func resolveCasesRoot(
    bundle: Bundle = .main,
    fileManager: FileManager = .default
  ) -> URL? {
    if let bundled = bundle.resourceURL?.appendingPathComponent("Cases", isDirectory: true),
      fileManager.fileExists(atPath: bundled.path)
    {
      return bundled
    }
    var dir = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    for _ in 0..<6 {
      let candidate = dir.appendingPathComponent("cases", isDirectory: true)
      if fileManager.fileExists(atPath: candidate.path) { return candidate }
      dir = dir.deletingLastPathComponent()
    }
    return nil
  }
}
