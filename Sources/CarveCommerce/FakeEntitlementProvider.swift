// Sources/CarveCommerce/FakeEntitlementProvider.swift
// Deterministic StoreKit stand-in. Never talks to the network.

import Foundation

@MainActor
public final class FakeEntitlementProvider: ObservableObject, EntitlementProviding {
  @Published public private(set) var snapshot: EntitlementSnapshot
  public var nextPurchase: PurchaseOutcome = .purchased
  public var nextRestore: RestoreOutcome = .restored([])
  public var refreshDelayNanoseconds: UInt64 = 0

  public init(snapshot: EntitlementSnapshot = EntitlementSnapshot()) {
    self.snapshot = snapshot
  }

  public func seed(product: StoreProduct, status: EntitlementStatus = .notOwned) {
    snapshot.products[product.productId] = product
    snapshot.entitlements[product.productId] = status
    snapshot.loadState = .loaded
  }

  public func failLoad(_ message: String) {
    snapshot.loadState = .failed(message)
  }

  public func markUnavailable() {
    snapshot.loadState = .unavailable
  }

  public func refresh() async {
    if refreshDelayNanoseconds > 0 {
      try? await Task.sleep(nanoseconds: refreshDelayNanoseconds)
    }
    if snapshot.loadState == .idle {
      snapshot.loadState = .loaded
    }
  }

  public func purchase(productId: String) async -> PurchaseOutcome {
    switch nextPurchase {
    case .purchased:
      snapshot.entitlements[productId] = .owned
      return .purchased
    case .unverified:
      return .unverified
    case .cancelled:
      return .cancelled
    case .pending:
      return .pending
    case .failed(let message):
      return .failed(message)
    case .unavailable:
      return .unavailable
    }
  }

  public func restorePurchases() async -> RestoreOutcome {
    switch nextRestore {
    case .restored(let ids):
      for id in ids {
        snapshot.entitlements[id] = .owned
      }
      return nextRestore
    case .failed, .unavailable:
      return nextRestore
    }
  }

  public func setRevokedForTesting(_ productId: String, revoked: Bool) {
    snapshot.entitlements[productId] = revoked ? .revoked : .owned
  }
}
