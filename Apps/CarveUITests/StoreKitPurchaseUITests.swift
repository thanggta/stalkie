// Apps/CarveUITests/StoreKitPurchaseUITests.swift
// StoreKit-configured paid path via the scheme's .storekit file.
// This is not proof that the App Store Connect product exists.

import XCTest
import StoreKitTest

@MainActor
final class StoreKitPurchaseUITests: XCTestCase {
  private static let paidProductId = "games.carve.case.dont_wait_up"
  var storeSession: SKTestSession?

  override func setUpWithError() throws {
    continueAfterFailure = false
    // Scheme TestAction attaches Carve/Carve.storekit to games.carve.app.
    // SKTestSession must use the same configuration so buy/restore share the
    // app under test's StoreKitTest environment.
    let session = try makeStoreSession()
    session.disableDialogs = true
    session.resetToDefaultState()
    storeSession = session
  }

  override func tearDownWithError() throws {
    storeSession?.resetToDefaultState()
    storeSession = nil
  }

  func testPaidCaseStaysLockedUntilVerifiedPurchase() throws {
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
    tapIdentifier(app, "purchase-buy", timeout: 5)
    XCTAssertTrue(
      app.descendants(matching: .any)["phone-root"].waitForExistence(timeout: 20),
      "verified purchase should launch the case without restart")
  }

  func testRestorePurchasesUnlocksWithoutRestart() async throws {
    let session = try XCTUnwrap(storeSession)
    _ = try await session.buyProduct(identifier: Self.paidProductId)

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
