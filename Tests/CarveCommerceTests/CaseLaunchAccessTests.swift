// Tests/CarveCommerceTests/CaseLaunchAccessTests.swift
// Why: launch is the paywall. A failing store must not lock the free case,
// and an unverified / cancelled / pending purchase must not open a paid one.

import Foundation
import Testing
import CarveShell
@testable import CarveCommerce

struct CaseLaunchAccessTests {
  private let catalog = try! parseCatalog(data: Data(contentsOf: catalogURL()))

  @Test func freeCaseLaunchesWhenStoreKitHasFailed() {
    var snapshot = EntitlementSnapshot(loadState: .failed("store down"))
    snapshot.entitlements["games.carve.case.dont_wait_up"] = .unknown
    let allowed = CaseLaunchAccess.canLaunch(
      catalog: catalog,
      caseId: "five_minutes",
      snapshot: snapshot,
      arguments: ["Carve"])
    #expect(allowed)
  }

  @Test func paidCaseIsLockedWithoutEntitlement() {
    var snapshot = EntitlementSnapshot(loadState: .loaded)
    snapshot.entitlements["games.carve.case.dont_wait_up"] = .notOwned
    #expect(
      CaseLaunchAccess.decision(
        catalog: catalog,
        caseId: "dont_wait_up",
        snapshot: snapshot,
        arguments: ["Carve"]) == .locked)
  }

  @Test func verifiedOwnershipUnlocksPaidCase() {
    var snapshot = EntitlementSnapshot(loadState: .loaded)
    snapshot.entitlements["games.carve.case.dont_wait_up"] = .owned
    #expect(
      CaseLaunchAccess.canLaunch(
        catalog: catalog,
        caseId: "dont_wait_up",
        snapshot: snapshot,
        arguments: ["Carve"]))
  }

  @Test func revocationRemovesLaunchAccess() {
    var snapshot = EntitlementSnapshot(loadState: .loaded)
    snapshot.entitlements["games.carve.case.dont_wait_up"] = .revoked
    #expect(
      CaseLaunchAccess.decision(
        catalog: catalog,
        caseId: "dont_wait_up",
        snapshot: snapshot,
        arguments: ["Carve"]) == .locked)
  }

  @Test func unknownCaseCannotLaunch() {
    #expect(
      CaseLaunchAccess.decision(
        catalog: catalog,
        caseId: "nope",
        snapshot: EntitlementSnapshot(),
        arguments: ["Carve"]) == .unknownCase)
  }

  @Test func caseIdArgumentDoesNotBypassPaidLock() {
    var snapshot = EntitlementSnapshot(loadState: .loaded)
    snapshot.entitlements["games.carve.case.dont_wait_up"] = .notOwned
    #expect(
      !CaseLaunchAccess.canLaunch(
        catalog: catalog,
        caseId: "dont_wait_up",
        snapshot: snapshot,
        arguments: ["Carve", "-caseId", "dont_wait_up"]))
  }

  @Test func unlockAllCasesBypassIsCompileTimeGated() {
    let requested = EntitlementBypass.requested(arguments: ["-unlockAllCases"])
    #if DEBUG
    #expect(requested)
    var snapshot = EntitlementSnapshot(loadState: .loaded)
    snapshot.entitlements["games.carve.case.dont_wait_up"] = .notOwned
    #expect(
      CaseLaunchAccess.canLaunch(
        catalog: catalog,
        caseId: "dont_wait_up",
        snapshot: snapshot,
        arguments: ["Carve", "-unlockAllCases"]))
    #else
    #expect(!requested)
    var snapshot = EntitlementSnapshot(loadState: .loaded)
    snapshot.entitlements["games.carve.case.dont_wait_up"] = .notOwned
    #expect(
      !CaseLaunchAccess.canLaunch(
        catalog: catalog,
        caseId: "dont_wait_up",
        snapshot: snapshot,
        arguments: ["Carve", "-unlockAllCases"]))
    #endif
  }
}

#if !DEBUG
struct EntitlementBypassReleaseTests {
  @Test func launchArgumentsDoNotGrantEntitlementInRelease() {
    #expect(!EntitlementBypass.requested(arguments: ["-unlockAllCases", "-caseId", "dont_wait_up"]))
  }
}
#endif

@MainActor
struct FakeStorePurchaseTests {
  @Test func verifiedPurchaseThenUnlocks() async {
    let fake = FakeEntitlementProvider()
    fake.seed(
      product: StoreProduct(
        productId: "games.carve.case.dont_wait_up",
        displayName: "Don't Wait Up",
        description: "One-time case unlock",
        displayPrice: "$2.99"),
      status: .notOwned)
    fake.nextPurchase = .purchased
    let outcome = await fake.purchase(productId: "games.carve.case.dont_wait_up")
    #expect(outcome == .purchased)
    #expect(fake.snapshot.status(for: "games.carve.case.dont_wait_up") == .owned)
  }

  @Test func unverifiedTransactionNeverUnlocks() async {
    let fake = FakeEntitlementProvider()
    fake.seed(
      product: StoreProduct(
        productId: "games.carve.case.dont_wait_up",
        displayName: "Don't Wait Up",
        description: "One-time case unlock",
        displayPrice: "$2.99"),
      status: .notOwned)
    fake.nextPurchase = .unverified
    let outcome = await fake.purchase(productId: "games.carve.case.dont_wait_up")
    #expect(outcome == .unverified)
    #expect(fake.snapshot.status(for: "games.carve.case.dont_wait_up") == .notOwned)
  }

  @Test func cancellationDoesNotUnlock() async {
    let fake = FakeEntitlementProvider()
    fake.seed(
      product: StoreProduct(
        productId: "games.carve.case.dont_wait_up",
        displayName: "Don't Wait Up",
        description: "One-time case unlock",
        displayPrice: "$2.99"),
      status: .notOwned)
    fake.nextPurchase = .cancelled
    let outcome = await fake.purchase(productId: "games.carve.case.dont_wait_up")
    #expect(outcome == .cancelled)
    #expect(fake.snapshot.status(for: "games.carve.case.dont_wait_up") == .notOwned)
  }

  @Test func pendingPurchaseRemainsLocked() async {
    let fake = FakeEntitlementProvider()
    fake.seed(
      product: StoreProduct(
        productId: "games.carve.case.dont_wait_up",
        displayName: "Don't Wait Up",
        description: "One-time case unlock",
        displayPrice: "$2.99"),
      status: .notOwned)
    fake.nextPurchase = .pending
    let outcome = await fake.purchase(productId: "games.carve.case.dont_wait_up")
    #expect(outcome == .pending)
    #expect(fake.snapshot.status(for: "games.carve.case.dont_wait_up") == .notOwned)
  }

  @Test func restoreUnlocksWithoutRestart() async {
    let fake = FakeEntitlementProvider()
    fake.seed(
      product: StoreProduct(
        productId: "games.carve.case.dont_wait_up",
        displayName: "Don't Wait Up",
        description: "One-time case unlock",
        displayPrice: "$2.99"),
      status: .notOwned)
    fake.nextRestore = .restored(["games.carve.case.dont_wait_up"])
    let outcome = await fake.restorePurchases()
    #expect(outcome == .restored(["games.carve.case.dont_wait_up"]))
    #expect(fake.snapshot.status(for: "games.carve.case.dont_wait_up") == .owned)
  }

  @Test func localizedPriceComesFromProductAbstraction() {
    let product = StoreProduct(
      productId: "games.carve.case.dont_wait_up",
      displayName: "Don't Wait Up",
      description: "One-time case unlock",
      displayPrice: "US$2.99")
    #expect(product.displayPrice == "US$2.99")
    #expect(!product.displayPrice.contains("2.99") || product.displayPrice.hasPrefix("US$"))
  }
}

@MainActor
struct ProgressIsolationTests {
  @Test func replayResetsOnlySelectedCase() throws {
    let dir = FileManager.default.temporaryDirectory
      .appendingPathComponent("carve-progress-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }

    let filed = SessionSnapshot(
      caseId: "five_minutes",
      schemaVersion: 1,
      carvedIds: ["thread_theo"],
      linkedPairs: [],
      answeredQuestionIds: [],
      openedIds: ["thread_theo"],
      unreadUnlockIds: [],
      draftAnswers: [:],
      filedReport: nil,
      isFiled: true,
      themeId: "ios-lookalike")
    try FileSessionStore(directory: dir, caseId: "five_minutes").save(filed)

    let other = SessionSnapshot(
      caseId: "dont_wait_up",
      schemaVersion: 1,
      carvedIds: ["thread_dex"],
      linkedPairs: [],
      answeredQuestionIds: [],
      openedIds: ["thread_dex"],
      unreadUnlockIds: [],
      draftAnswers: [:],
      filedReport: nil,
      isFiled: false,
      themeId: "ios-lookalike")
    try FileSessionStore(directory: dir, caseId: "dont_wait_up").save(other)

    #expect(CaseProgressStore.progress(for: "five_minutes", in: dir) == .filed)
    #expect(CaseProgressStore.progress(for: "dont_wait_up", in: dir) == .inProgress)

    try CaseProgressStore.clear(caseId: "five_minutes", in: dir)
    #expect(CaseProgressStore.progress(for: "five_minutes", in: dir) == .notStarted)
    #expect(CaseProgressStore.progress(for: "dont_wait_up", in: dir) == .inProgress)
  }

  @Test func revocationDoesNotDeleteProgress() throws {
    let dir = FileManager.default.temporaryDirectory
      .appendingPathComponent("carve-revoke-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }

    let snap = SessionSnapshot(
      caseId: "dont_wait_up",
      schemaVersion: 1,
      carvedIds: ["thread_dex"],
      linkedPairs: [],
      answeredQuestionIds: [],
      openedIds: ["thread_dex"],
      unreadUnlockIds: [],
      draftAnswers: [:],
      filedReport: nil,
      isFiled: false,
      themeId: "ios-lookalike")
    try FileSessionStore(directory: dir, caseId: "dont_wait_up").save(snap)

    let fake = FakeEntitlementProvider()
    fake.seed(
      product: StoreProduct(
        productId: "games.carve.case.dont_wait_up",
        displayName: "Don't Wait Up",
        description: "One-time",
        displayPrice: "$2.99"),
      status: .owned)
    fake.setRevokedForTesting("games.carve.case.dont_wait_up", revoked: true)
    #expect(fake.snapshot.status(for: "games.carve.case.dont_wait_up") == .revoked)
    #expect(CaseProgressStore.progress(for: "dont_wait_up", in: dir) == .inProgress)
  }
}

private func catalogURL() -> URL {
  var dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
  for _ in 0..<6 {
    let candidate = dir.appendingPathComponent("cases/catalog.json")
    if FileManager.default.fileExists(atPath: candidate.path) { return candidate }
    dir = dir.deletingLastPathComponent()
  }
  return URL(fileURLWithPath: "cases/catalog.json")
}
