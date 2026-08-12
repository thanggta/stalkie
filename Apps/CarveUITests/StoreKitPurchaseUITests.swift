// Apps/CarveUITests/StoreKitPurchaseUITests.swift
// StoreKit-configured paid path. Uses the scheme's .storekit file.
// This is not proof that the App Store Connect product exists.

import XCTest
import StoreKitTest

final class StoreKitPurchaseUITests: XCTestCase {
  var storeSession: SKTestSession?

  override func setUpWithError() throws {
    continueAfterFailure = false
    let bundle = Bundle(for: StoreKitPurchaseUITests.self)
    let url = try XCTUnwrap(
      bundle.url(forResource: "Carve", withExtension: "storekit"),
      "Carve.storekit must be copied into the UI test bundle")
    let session = try SKTestSession(contentsOf: url)
    session.resetToDefaultState()
    session.disableDialogs = true
    storeSession = session
  }

  override func tearDownWithError() throws {
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
    XCTAssertTrue(buy.waitForExistence(timeout: 15), "missing purchase-buy")
    // Price/product load is async; keep retrying until the control is enabled.
    let deadline = Date().addingTimeInterval(15)
    while Date() < deadline, !buy.firstMatch.isHittable {
      RunLoop.current.run(until: Date().addingTimeInterval(0.2))
    }
    tapIdentifier(app, "purchase-buy", timeout: 5)
    XCTAssertTrue(
      app.descendants(matching: .any)["phone-root"].waitForExistence(timeout: 20),
      "verified purchase should launch the case without restart")
  }

  func testRestorePurchasesUnlocksWithoutRestart() throws {
    try storeSession?.buyProduct(productIdentifier: "games.carve.case.dont_wait_up")

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
