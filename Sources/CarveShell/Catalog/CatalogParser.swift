// Sources/CarveShell/Catalog/CatalogParser.swift
// Unknown fields and types fail. Product IDs stay in this manifest.

import Foundation
import CarveCore

private let catalogRootKeys: Set<String> = ["schemaVersion", "cases"]
private let catalogEntryKeys: Set<String> = [
  "id", "title", "summary", "artwork", "order", "access", "availability", "productId",
]

public func parseCatalog(data: Data) throws -> CaseCatalog {
  do {
    try validateStrictJSON(data)
  } catch let error as StrictJSONError {
    throw CatalogFormatError("catalog.json: \(error)")
  }

  guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
    throw CatalogFormatError("catalog.json: root must be an object.")
  }

  let unknownRoot = Set(root.keys).subtracting(catalogRootKeys)
  if !unknownRoot.isEmpty {
    throw CatalogFormatError(
      "catalog.json: unknown field(s) \(unknownRoot.sorted().joined(separator: ", ")).")
  }

  guard let schema = root["schemaVersion"] as? Int else {
    throw CatalogFormatError("catalog.json: schemaVersion must be an integer.")
  }
  guard schema == 1 else {
    throw CatalogFormatError(
      "Unsupported catalog schemaVersion \"\(schema)\". This build supports 1 only.")
  }

  guard let rawCases = root["cases"] as? [Any] else {
    throw CatalogFormatError("catalog.json: cases must be an array.")
  }

  var entries: [CatalogEntry] = []
  for (index, item) in rawCases.enumerated() {
    guard let object = item as? [String: Any] else {
      throw CatalogFormatError("catalog.json: cases[\(index)] must be an object.")
    }
    entries.append(try parseEntry(object, index: index))
  }

  return CaseCatalog(schemaVersion: schema, entries: entries)
}

private func parseEntry(_ object: [String: Any], index: Int) throws -> CatalogEntry {
  let unknown = Set(object.keys).subtracting(catalogEntryKeys)
  if !unknown.isEmpty {
    throw CatalogFormatError(
      "catalog.json: cases[\(index)] unknown field(s) \(unknown.sorted().joined(separator: ", ")).")
  }

  let id = try requireString(object, "id", index: index)
  let title = try requireString(object, "title", index: index)
  let summary = try requireString(object, "summary", index: index)
  let artwork = try requireString(object, "artwork", index: index)
  guard let order = object["order"] as? Int else {
    throw CatalogFormatError("catalog.json: cases[\(index)] order must be an integer.")
  }

  guard let accessRaw = object["access"] as? String,
    let access = CatalogAccess(rawValue: accessRaw)
  else {
    throw CatalogFormatError(
      "catalog.json: cases[\(index)] access must be \"free\" or \"paid\".")
  }

  guard let availabilityRaw = object["availability"] as? String,
    let availability = CatalogAvailability(rawValue: availabilityRaw)
  else {
    throw CatalogFormatError(
      "catalog.json: cases[\(index)] availability must be \"available\" or \"comingSoon\".")
  }

  let productId: String?
  if let raw = object["productId"] {
    guard let value = raw as? String, !value.isEmpty else {
      throw CatalogFormatError(
        "catalog.json: cases[\(index)] productId must be a non-empty string.")
    }
    productId = value
  } else {
    productId = nil
  }

  return CatalogEntry(
    caseId: id,
    title: title,
    summary: summary,
    artwork: artwork,
    order: order,
    access: access,
    productId: productId,
    availability: availability)
}

private func requireString(_ object: [String: Any], _ key: String, index: Int) throws -> String {
  guard let value = object[key] as? String, !value.isEmpty else {
    throw CatalogFormatError("catalog.json: cases[\(index)] \(key) must be a non-empty string.")
  }
  return value
}
