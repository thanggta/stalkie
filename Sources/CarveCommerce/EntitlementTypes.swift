// Sources/CarveCommerce/EntitlementTypes.swift
// Purchase-verification types. Views display these; they do not decide them.

import Foundation

public enum EntitlementStatus: Equatable, Sendable {
  case unknown
  case notOwned
  case owned
  case revoked
}

public enum ProductLoadState: Equatable, Sendable {
  case idle
  case loading
  case loaded
  case failed(String)
  case unavailable
}

public enum PurchasePhase: Equatable, Sendable {
  case idle
  case purchasing
  case purchased
  case pending
  case cancelled
  case failed(String)
  case unavailable
  case revoked
}

public enum PurchaseOutcome: Equatable, Sendable {
  case purchased
  case cancelled
  case pending
  case unverified
  case failed(String)
  case unavailable
}

public enum RestoreOutcome: Equatable, Sendable {
  case restored([String])
  case failed(String)
  case unavailable
}

public struct StoreProduct: Equatable, Sendable, Identifiable {
  public var id: String { productId }
  public let productId: String
  public let displayName: String
  public let description: String
  public let displayPrice: String

  public init(
    productId: String,
    displayName: String,
    description: String,
    displayPrice: String
  ) {
    self.productId = productId
    self.displayName = displayName
    self.description = description
    self.displayPrice = displayPrice
  }
}

public struct EntitlementSnapshot: Equatable, Sendable {
  public var products: [String: StoreProduct]
  public var entitlements: [String: EntitlementStatus]
  public var loadState: ProductLoadState

  public init(
    products: [String: StoreProduct] = [:],
    entitlements: [String: EntitlementStatus] = [:],
    loadState: ProductLoadState = .idle
  ) {
    self.products = products
    self.entitlements = entitlements
    self.loadState = loadState
  }

  public func status(for productId: String) -> EntitlementStatus {
    entitlements[productId] ?? .unknown
  }

  public func product(id: String) -> StoreProduct? {
    products[id]
  }
}

public enum CaseLaunchDecision: Equatable, Sendable {
  case allowed
  case locked
  case comingSoon
  case unknownCase
}

public enum CaseProgress: Equatable, Sendable {
  case notStarted
  case inProgress
  case filed
}
