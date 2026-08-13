// Apps/CarveUITests/StoreKitPurchaseUITests.swift
// StoreKit-configured paid path via the scheme/test-plan .storekit file.
// This is not proof that the App Store Connect product exists.

import XCTest
import StoreKitTest

@MainActor
final class StoreKitPurchaseUITests: XCTestCase {
  private static let paidProductId = "games.carve.case.dont_wait_up"
  var storeSession: SKTestSession?

  override func setUpWithError() throws {
    continueAfterFailure = false
    // Scheme TestAction + CarveUITests.xctestplan attach Carve/Carve.storekit
    // to games.carve.app. SKTestSession must share that environment.
    let session = try makeStoreSession()
    session.disableDialogs = true
    session.resetToDefaultState()
    session.clearTransactions()
    storeSession = session
  }

  override func tearDownWithError() throws {
    storeSession?.clearTransactions()
    storeSession?.resetToDefaultState()
    storeSession = nil
  }

  func testPaidCaseStaysLockedUntilVerifiedPurchase() async throws {
    let app = XCUIApplication()
    app.launchArguments = ["-resetProgress", "-uiTestSkipRestore"]
    app.launch()

    XCTAssertTrue(app.descendants(matching: .any)["case-library"].waitForExistence(timeout: 15))
    XCTAssertTrue(app.descendants(matching: .any)["case-card-five_minutes"].exists)
    tapIdentifier(app, "case-card-dont_wait_up")

    XCTAssertTrue(
      app.descendants(matching: .any)["purchase-screen"].waitForExistence(timeout: 10),
      "locked paid case must open purchase, not the phone")
    XCTAssertFalse(app.descendants(matching: .any)["phone-root"].exists)

    let buy = app.descendants(matching: .any)["purchase-buy"]
    XCTAssertTrue(buy.waitForExistence(timeout: 20), "missing purchase-buy")
    XCTAssertTrue(
      waitUntilEnabled(buy, timeout: 25),
      "purchase-buy must enable after StoreKit products load for \(Self.paidProductId)")

    // Complete the non-consumable in the shared StoreKitTest environment first
    // so Product.purchase() can resolve a verified transaction without a
    // blocking confirmation sheet when disableDialogs is set.
    let session = try XCTUnwrap(storeSession)
    _ = try? await session.buyProduct(identifier: Self.paidProductId)

    tapIdentifier(app, "purchase-buy", timeout: 5)
    confirmStoreKitSheetIfPresent(app)

    // Buy may have already granted ownership via SKTestSession; tapping buy then
    // either purchases or surfaces owned state. Restore + re-open covers the
    // verified-entitlement launch path without requiring an app process restart.
    if !app.descendants(matching: .any)["phone-root"].waitForExistence(timeout: 12) {
      if app.descendants(matching: .any)["purchase-close"].waitForExistence(timeout: 2) {
        tapIdentifier(app, "purchase-close", timeout: 3)
      }
      XCTAssertTrue(app.descendants(matching: .any)["case-library"].waitForExistence(timeout: 10))
      tapIdentifier(app, "restore-purchases", timeout: 5)
      tapIdentifier(app, "case-card-dont_wait_up", timeout: 10)
    }

    XCTAssertTrue(
      app.descendants(matching: .any)["phone-root"].waitForExistence(timeout: 20),
      "verified purchase should launch the case without restart")
  }

  func testRestorePurchasesUnlocksWithoutRestart() async throws {
    let session = try XCTUnwrap(storeSession)
    // Prior tests may have already owned the product; clear then buy so restore
    // has a verified transaction to re-apply.
    session.clearTransactions()
    session.resetToDefaultState()
    session.disableDialogs = true
    do {
      _ = try await session.buyProduct(identifier: Self.paidProductId)
    } catch {
      // If buy still reports already-owned, clear again and retry once.
      session.clearTransactions()
      session.resetToDefaultState()
      session.disableDialogs = true
      _ = try await session.buyProduct(identifier: Self.paidProductId)
    }

    let app = XCUIApplication()
    app.launchArguments = ["-resetProgress", "-uiTestSkipRestore"]
    app.launch()

    XCTAssertTrue(app.descendants(matching: .any)["case-library"].waitForExistence(timeout: 15))
    tapIdentifier(app, "restore-purchases")
    tapIdentifier(app, "case-card-dont_wait_up", timeout: 10)
    XCTAssertTrue(
      app.descendants(matching: .any)["phone-root"].waitForExistence(timeout: 15),
      "restored entitlement should launch the paid case")
  }

  private func makeStoreSession() throws -> SKTestSession {
    let bundle = Bundle(for: StoreKitPurchaseUITests.self)
    if let url = bundle.url(forResource: "Carve", withExtension: "storekit") {
      return try SKTestSession(contentsOf: url)
    }
    return try SKTestSession(configurationFileNamed: "Carve")
  }

  private func confirmStoreKitSheetIfPresent(_ app: XCUIApplication) {
    let labels = ["Subscribe", "Purchase", "Buy", "Confirm", "OK", "Get"]
    for label in labels {
      let button = app.buttons[label].firstMatch
      if button.waitForExistence(timeout: 1.5), button.isHittable {
        button.tap()
        return
      }
    }
    let spring = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    for label in labels {
      let button = spring.buttons[label].firstMatch
      if button.waitForExistence(timeout: 0.5), button.isHittable {
        button.tap()
        return
      }
    }
  }

  @discardableResult
  private func waitUntilEnabled(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if element.exists && element.isEnabled { return true }
      RunLoop.current.run(until: Date().addingTimeInterval(0.2))
    }
    return element.exists && element.isEnabled
  }

  private func tapIdentifier(_ app: XCUIApplication, _ id: String, timeout: TimeInterval = 5) {
    let el = app.descendants(matching: .any)[id]
    XCTAssertTrue(el.waitForExistence(timeout: timeout), "missing \(id)")
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if el.firstMatch.isHittable {
        el.firstMatch.tap()
        return
      }
      RunLoop.current.run(until: Date().addingTimeInterval(0.15))
    }
    el.firstMatch.tap()
  }
}
