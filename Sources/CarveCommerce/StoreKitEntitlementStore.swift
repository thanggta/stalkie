// Sources/CarveCommerce/StoreKitEntitlementStore.swift
// StoreKit 2 only. Verified transactions grant access. No receipt crypto.

import Foundation
import StoreKit
import CarveShell

@MainActor
public final class StoreKitEntitlementStore: ObservableObject, EntitlementProviding {
  @Published public private(set) var snapshot = EntitlementSnapshot()

  private let productIds: [String]
  private var updatesTask: Task<Void, Never>?

  public init(productIds: [String]) {
    self.productIds = productIds
    updatesTask = Task { [weak self] in
      await self?.listenForUpdates()
    }
  }

  deinit {
    updatesTask?.cancel()
  }

  public func refresh() async {
    snapshot.loadState = .loading
    do {
      let products = try await Product.products(for: Set(productIds))
      var mapped: [String: StoreProduct] = [:]
      for product in products {
        mapped[product.id] = StoreProduct(
          productId: product.id,
          displayName: product.displayName,
          description: product.description,
          displayPrice: product.displayPrice)
      }
      var next = snapshot
      next.products = mapped
      next.loadState = products.isEmpty && !productIds.isEmpty ? .unavailable : .loaded
      snapshot = next
      await applyCurrentEntitlements()
    } catch {
      var next = snapshot
      next.loadState = .failed(error.localizedDescription)
      snapshot = next
    }
  }

  public func purchase(productId: String) async -> PurchaseOutcome {
    do {
      let products = try await Product.products(for: [productId])
      guard let product = products.first else {
        return .unavailable
      }
      let result = try await product.purchase()
      switch result {
      case .success(let verification):
        guard let transaction = verified(verification) else {
          return .unverified
        }
        var next = snapshot
        next.entitlements[productId] = .owned
        next.products[productId] = StoreProduct(
          productId: product.id,
          displayName: product.displayName,
          description: product.description,
          displayPrice: product.displayPrice)
        snapshot = next
        await transaction.finish()
        return .purchased
      case .userCancelled:
        return .cancelled
      case .pending:
        return .pending
      @unknown default:
        return .failed("The store returned an unknown purchase result.")
      }
    } catch {
      return .failed(error.localizedDescription)
    }
  }

  public func restorePurchases() async -> RestoreOutcome {
    do {
      try await AppStore.sync()
      let owned = await applyCurrentEntitlements()
      return .restored(owned)
    } catch {
      return .failed(error.localizedDescription)
    }
  }

  public func setRevokedForTesting(_ productId: String, revoked: Bool) {
    var next = snapshot
    next.entitlements[productId] = revoked ? .revoked : .owned
    snapshot = next
  }

  @discardableResult
  private func applyCurrentEntitlements() async -> [String] {
    var owned: [String] = []
    var next = snapshot.entitlements
    for id in productIds where next[id] == nil {
      next[id] = .notOwned
    }

    for await result in Transaction.currentEntitlements {
      guard let transaction = verified(result) else { continue }
      if transaction.revocationDate != nil {
        next[transaction.productID] = .revoked
      } else {
        next[transaction.productID] = .owned
        owned.append(transaction.productID)
      }
    }
    var snap = snapshot
    snap.entitlements = next
    snapshot = snap
    return owned
  }

  private func listenForUpdates() async {
    for await result in Transaction.updates {
      guard let transaction = verified(result) else { continue }
      var next = snapshot
      if transaction.revocationDate != nil {
        next.entitlements[transaction.productID] = .revoked
      } else {
        next.entitlements[transaction.productID] = .owned
      }
      snapshot = next
      await transaction.finish()
    }
  }

  private func verified<T>(_ result: VerificationResult<T>) -> T? {
    switch result {
    case .verified(let value):
      return value
    case .unverified:
      return nil
    }
  }
}
