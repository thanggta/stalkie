// Sources/CarveCommerce/CaseLaunchAccess.swift
// Entitlement controls whether a case may launch, never what is visible inside.

import Foundation
import CarveShell

public enum CaseLaunchAccess {
  public static func decision(
    entry: CatalogEntry?,
    entitlement: EntitlementStatus,
    bypass: Bool
  ) -> CaseLaunchDecision {
    guard let entry else { return .unknownCase }
    if entry.availability == .comingSoon { return .comingSoon }
    switch entry.access {
    case .free:
      return .allowed
    case .paid:
      if bypass { return .allowed }
      switch entitlement {
      case .owned:
        return .allowed
      case .revoked, .notOwned, .unknown:
        return .locked
      }
    }
  }

  public static func decision(
    catalog: CaseCatalog,
    caseId: String,
    snapshot: EntitlementSnapshot,
    arguments: [String]
  ) -> CaseLaunchDecision {
    let entry = catalog.entry(id: caseId)
    let productId = entry?.productId
    let entitlement = productId.map { snapshot.status(for: $0) } ?? .unknown
    return decision(
      entry: entry,
      entitlement: entitlement,
      bypass: EntitlementBypass.requested(arguments: arguments))
  }

  public static func canLaunch(
    catalog: CaseCatalog,
    caseId: String,
    snapshot: EntitlementSnapshot,
    arguments: [String]
  ) -> Bool {
    decision(
      catalog: catalog,
      caseId: caseId,
      snapshot: snapshot,
      arguments: arguments) == .allowed
  }
}
