// Apps/CarveUITests/FullLoopUITests.swift
// Full simulator loop: browse → link → decide → file → relaunch restores filed state.
// Identifiers only — no pixel coordinates.

import XCTest

final class FullLoopUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testFullLoopFiveMinutesToFiledRestore() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-resetProgress", "-uiTestSkipRestore"]
    app.launch()

    XCTAssertTrue(
      app.descendants(matching: .any)["case-library"].waitForExistence(timeout: 15),
      "library should appear on first launch")
    tapIdentifier(app, "case-card-five_minutes")

    // Home shell is up (not the white failure screen).
    XCTAssertTrue(
      app.descendants(matching: .any)["phone-root"].waitForExistence(timeout: 15),
      "phone root should appear after launching the free case")

    // Open Messages from the dock.
    tapIdentifier(app, "app-messages")

    // Open Theo (initial), then Sable once unlocked.
    tapIdentifier(app, "messages-thread-thread_theo")
    if app.buttons["Back"].waitForExistence(timeout: 3) {
      app.buttons["Back"].firstMatch.tap()
    }

    XCTAssertTrue(
      app.descendants(matching: .any)["messages-thread-thread_sable"].waitForExistence(timeout: 8),
      "Sable thread should unlock after Theo")
    tapIdentifier(app, "messages-thread-thread_sable")

    goHome(app)

    // Link board: connect Eli and Sable
    tapIdentifier(app, "app-board", timeout: 8)
    XCTAssertTrue(
      app.descendants(matching: .any)["link-entity-eli"].waitForExistence(timeout: 8),
      "Eli should appear after carved threads")
    tapIdentifier(app, "link-entity-eli")
    tapIdentifier(app, "link-entity-sable")

    goHome(app)

    // Location fragment unlocks after the link — open Maps.
    tapIdentifier(app, "app-places")
    let riverVisible =
      app.descendants(matching: .any)["maps-pin-river_court"].waitForExistence(timeout: 8)
      || app.descendants(matching: .any)["maps-visit-river_court"].waitForExistence(timeout: 2)
    XCTAssertTrue(riverVisible, "linked-gated River Court location should be visible in Maps")

    goHome(app)

    // Decide flow — answer all 15. Decide is hidden until Sable is carved.
    tapIdentifier(app, "app-decide", timeout: 10)
    tapIdentifier(app, "verdict-ready")

    let answers: [(String, String)] = [
      ("q_sable_who", "affair"),
      ("q_thursday_lie", "yes"),
      ("q_thursday_where", "with_sable"),
      ("q_theo_cover", "yes"),
      ("q_theo_knew", "unknown"),
      ("q_usual_place", "sable_place"),
      ("q_rae_mentioned", "yes"),
      ("q_hide_phone", "yes"),
      ("q_ivy_party", "no"),
      ("q_ivy_knows_affair", "unknown"),
      ("q_how_long", "weeks"),
      ("q_unsent_to", "sable"),
      ("q_still_active", "yes"),
      ("q_mom_related", "no"),
      ("q_leaving", "unknown"),
    ]

    for (qid, option) in answers {
      tapIdentifier(app, "verdict-option-\(qid)-\(option)", timeout: 6)
      tapIdentifier(app, "verdict-next", timeout: 6)
    }

    tapIdentifier(app, "verdict-review-continue")
    tapIdentifier(app, "verdict-file")

    XCTAssertTrue(
      app.descendants(matching: .any)["verdict-results-title"].waitForExistence(timeout: 8),
      "results screen after filing")

    // Relaunch without reset — filed state must restore.
    app.terminate()
    let app2 = XCUIApplication()
    app2.launchArguments = []  // restore saved snapshot
    app2.launch()

    XCTAssertTrue(
      app2.descendants(matching: .any)["case-library"].waitForExistence(timeout: 15),
      "relaunch returns to the library")
    tapIdentifier(app2, "case-card-five_minutes")

    XCTAssertTrue(
      app2.descendants(matching: .any)["phone-root"].waitForExistence(timeout: 15))

    tapIdentifier(app2, "app-decide")

    XCTAssertTrue(
      app2.descendants(matching: .any)["verdict-results-title"].waitForExistence(timeout: 8),
      "relaunch should restore filed results, not a blank case")
  }

  private func goHome(_ app: XCUIApplication) {
    for _ in 0..<10 {
      if isOnSpringBoard(app) { return }

      // Prefer hittable identifiers only. Coordinate-tapping buried stack
      // elements looks like progress but does not navigate.
      if hittableTap(app.descendants(matching: .any)["nav-home"]) { continue }
      if hittableTap(app.descendants(matching: .any)["nav-back"]) { continue }
      if hittableTap(app.descendants(matching: .any)["instagram-home"]) { continue }
      if hittableTap(app.descendants(matching: .any)["snapchat-home"]) { continue }
      if hittableTap(app.buttons["Home"]) { continue }
      if hittableTap(app.buttons["Back"]) { continue }
      if hittableTap(app.descendants(matching: .any)["home-indicator"]) { continue }
    }
    XCTAssertTrue(isOnSpringBoard(app), "failed to return to SpringBoard home")
  }

  private func isOnSpringBoard(_ app: XCUIApplication) -> Bool {
    let messages = app.descendants(matching: .any)["app-messages"]
    return messages.waitForExistence(timeout: 1) && messages.firstMatch.isHittable
  }

  @discardableResult
  private func hittableTap(_ element: XCUIElement) -> Bool {
    guard element.exists, element.isHittable else { return false }
    element.tap()
    return true
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
