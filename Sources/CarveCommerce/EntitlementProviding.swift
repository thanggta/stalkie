// Sources/CarveCommerce/EntitlementProviding.swift
// Protocol so unit tests never need a live App Store.

import Foundation

@MainActor
public protocol EntitlementProviding: AnyObject {
  var snapshot: EntitlementSnapshot { get }
  func refresh() async
  func purchase(productId: String) async -> PurchaseOutcome
  func restorePurchases() async -> RestoreOutcome
  func setRevokedForTesting(_ productId: String, revoked: Bool)
}
