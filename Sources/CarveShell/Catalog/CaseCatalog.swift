// Sources/CarveShell/Catalog/CaseCatalog.swift
// Declarative production library. Ordering and access live here — never
// as Swift case-id branches, never as product IDs in views.

import Foundation

public enum CatalogAccess: String, Equatable, Sendable {
  case free
  case paid
}

public enum CatalogAvailability: String, Equatable, Sendable {
  case available
  case comingSoon
}

public struct CatalogEntry: Equatable, Sendable, Identifiable {
  public var id: String { caseId }
  public let caseId: String
  public let title: String
  public let summary: String
  public let artwork: String
  public let order: Int
  public let access: CatalogAccess
  public let productId: String?
  public let availability: CatalogAvailability

  public init(
    caseId: String,
    title: String,
    summary: String,
    artwork: String,
    order: Int,
    access: CatalogAccess,
    productId: String?,
    availability: CatalogAvailability
  ) {
    self.caseId = caseId
    self.title = title
    self.summary = summary
    self.artwork = artwork
    self.order = order
    self.access = access
    self.productId = productId
    self.availability = availability
  }
}

public struct CaseCatalog: Equatable, Sendable {
  public let schemaVersion: Int
  public let entries: [CatalogEntry]

  public init(schemaVersion: Int, entries: [CatalogEntry]) {
    self.schemaVersion = schemaVersion
    self.entries = entries.sorted { lhs, rhs in
      if lhs.order != rhs.order { return lhs.order < rhs.order }
      return lhs.caseId < rhs.caseId
    }
  }

  public func entry(id: String) -> CatalogEntry? {
    entries.first { $0.caseId == id }
  }

  public var paidProductIds: [String] {
    entries.compactMap(\.productId)
  }
}

public struct CatalogFormatError: Error, Equatable, CustomStringConvertible {
  public let message: String
  public init(_ message: String) { self.message = message }
  public var description: String { message }
}
