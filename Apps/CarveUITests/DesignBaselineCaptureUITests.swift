// Apps/CarveUITests/DesignBaselineCaptureUITests.swift
// Stage 1 baseline capture for the UI/UX redesign.
// Fails hard when the expected accessibility identifier is absent —
// blank or wrong-screen captures are not acceptable design evidence.

import XCTest

final class DesignBaselineCaptureUITests: XCTestCase {
  private var captureRoot: URL!

  override func setUpWithError() throws {
    continueAfterFailure = false
    let base: URL
    if let env = ProcessInfo.processInfo.environment["DESIGN_REVIEW_DIR"], !env.isEmpty {
      base = URL(fileURLWithPath: env, isDirectory: true)
    } else {
      // Resolve repo root from this source file: Apps/CarveUITests → repo.
      base = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("design-review/baseline", isDirectory: true)
    }
    let device =
      ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"]
      ?? ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"]
      ?? "simulator"
    captureRoot = base.appendingPathComponent(sanitize(device), isDirectory: true)
    try FileManager.default.createDirectory(
      at: captureRoot, withIntermediateDirectories: true)
  }

  func testCaptureFiveMinutesBaseline() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-resetProgress", "-uiTestSkipRestore"]
    app.launch()

    // --- Case library (not started) ---
    waitFor(app, "case-library", timeout: 20)
    capture(app, "01-library-not-started")

    // Locked paid card is visible on the same library.
    waitFor(app, "case-card-dont_wait_up")
    capture(app, "02-library-paid-locked-visible")

    // --- Purchase (available / loading price from StoreKit Testing) ---
    tap(app, "case-card-dont_wait_up")
    waitFor(app, "purchase-screen", timeout: 12)
    // Wait for either price or a load-failure state message.
    let priceReady = app.descendants(matching: .any)["purchase-price"].waitForExistence(timeout: 8)
    let stateReady = app.descendants(matching: .any)["purchase-state"].waitForExistence(timeout: 2)
    XCTAssertTrue(priceReady || stateReady, "purchase screen never showed price or state")
    capture(app, "03-purchase-available-or-loading")
    tap(app, "purchase-close")
    waitFor(app, "case-library")

    // --- Open free case ---
    tap(app, "case-card-five_minutes")
    waitFor(app, "phone-root", timeout: 15)
    waitFor(app, "app-messages", timeout: 8)
    // Decide must not be on the initial home for a clean five_minutes start.
    XCTAssertFalse(
      app.descendants(matching: .any)["app-decide"].waitForExistence(timeout: 1),
      "Decide should be hidden before readiness")
    capture(app, "04-home-initial")

    // --- Messages list ---
    tap(app, "app-messages")
    waitFor(app, "messages-thread-thread_theo", timeout: 8)
    capture(app, "05-messages-list")

    // --- Thread (Theo) ---
    tap(app, "messages-thread-thread_theo")
    // Thread detail has nav-back; wait for content to settle.
    RunLoop.current.run(until: Date().addingTimeInterval(0.6))
    capture(app, "06-messages-thread-theo")

    if app.buttons["Back"].waitForExistence(timeout: 3) {
      app.buttons["Back"].firstMatch.tap()
    } else {
      let back = app.descendants(matching: .any)["nav-back"]
      if back.exists {
        back.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
      }
    }

    waitFor(app, "messages-thread-thread_sable", timeout: 8)
    capture(app, "07-messages-list-after-sable-unlock")
    tap(app, "messages-thread-thread_sable")
    RunLoop.current.run(until: Date().addingTimeInterval(0.6))
    capture(app, "08-messages-thread-sable")
    goHome(app)

    // Home after Links can appear (two named people after Theo + Sable).
    waitFor(app, "app-board", timeout: 8)
    capture(app, "09-home-links-visible")

    // --- Notes ---
    if app.descendants(matching: .any)["app-notes"].waitForExistence(timeout: 3) {
      tap(app, "app-notes")
      RunLoop.current.run(until: Date().addingTimeInterval(0.5))
      capture(app, "10-notes")
      goHome(app)
    }

    // --- Phone / calls ---
    tap(app, "app-phone")
    RunLoop.current.run(until: Date().addingTimeInterval(0.5))
    capture(app, "11-phone-calls")
    goHome(app)

    // --- Photos ---
    tap(app, "app-photos")
    RunLoop.current.run(until: Date().addingTimeInterval(0.5))
    capture(app, "12-photos")
    // Prefer stable photos-item ids when present (redesign).
    if app.descendants(matching: .any)["photos-item-image_counter"].waitForExistence(timeout: 2)
      || app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "photos-item-")).firstMatch.waitForExistence(timeout: 1)
    {
      let item = app.descendants(matching: .any).matching(
        NSPredicate(format: "identifier BEGINSWITH %@", "photos-item-")).firstMatch
      if item.exists {
        item.tap()
        RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        capture(app, "13-image-detail")
        // Pop detail then app via nav chrome (two levels).
        for _ in 0..<3 {
          if isHome(app) { break }
          let back = app.descendants(matching: .any)["nav-back"]
          if back.exists { back.firstMatch.tap() }
          let home = app.descendants(matching: .any)["nav-home"]
          if home.exists, home.isHittable { home.tap(); break }
          RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        }
      }
    }
    if !isHome(app) { goHome(app) }

    // --- Instagram / Snapchat if icons present ---
    if app.descendants(matching: .any)["app-photo_social"].waitForExistence(timeout: 2) {
      tap(app, "app-photo_social")
      waitFor(app, "instagram-title", timeout: 6)
      capture(app, "14-instagram")
      goHome(app)
    }
    if app.descendants(matching: .any)["app-ephemeral_chat"].waitForExistence(timeout: 2) {
      tap(app, "app-ephemeral_chat")
      waitFor(app, "snapchat-title", timeout: 6)
      capture(app, "15-snapchat")
      goHome(app)
    }

    // --- Links: empty? (entities exist after threads) → selected → completed ---
    tap(app, "app-board", timeout: 8)
    waitFor(app, "link-entity-eli", timeout: 8)
    capture(app, "16-links-with-entities")
    tap(app, "link-entity-eli")
    capture(app, "17-links-selected-node")
    tap(app, "link-entity-sable")
    RunLoop.current.run(until: Date().addingTimeInterval(0.5))
    capture(app, "18-links-completed-connection")
    goHome(app)

    // --- Maps after gate ---
    waitFor(app, "app-places", timeout: 6)
    tap(app, "app-places")
    let river =
      app.descendants(matching: .any)["maps-pin-river_court"].waitForExistence(timeout: 8)
      || app.descendants(matching: .any)["maps-visit-river_court"].waitForExistence(timeout: 2)
    XCTAssertTrue(river, "Maps must show linked-gated River Court after Eli–Sable link")
    capture(app, "19-maps-after-gate")
    goHome(app)

    // Decide should now be visible after readiness.
    waitFor(app, "app-decide", timeout: 10)
    capture(app, "20-home-decide-visible")

    // --- Decide flow ---
    tap(app, "app-decide")
    waitFor(app, "verdict-ready", timeout: 8)
    capture(app, "21-decide-intro")
    tap(app, "verdict-ready")

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

    // Incomplete validation: press Next without selecting an answer → warning appears.
    waitFor(app, "verdict-next", timeout: 6)
    capture(app, "22-decide-question-section")
    tap(app, "verdict-next", timeout: 4)
    // Stay on question; incomplete copy should appear.
    RunLoop.current.run(until: Date().addingTimeInterval(0.3))
    capture(app, "22b-decide-incomplete-validation")

    // Complete all answers one by one.
    for (idx, (qid, option)) in answers.enumerated() {
      tap(app, "verdict-option-\(qid)-\(option)", timeout: 6)
      if idx == 0 {
        capture(app, "23-decide-section-filled")
      }
      tap(app, "verdict-next", timeout: 6)
    }

    waitFor(app, "verdict-review-continue", timeout: 12)
    capture(app, "24-decide-review")
    tap(app, "verdict-review-continue")
    waitFor(app, "verdict-file", timeout: 8)
    capture(app, "25-decide-confirm")
    tap(app, "verdict-file")

    waitFor(app, "verdict-results-title", timeout: 10)
    capture(app, "26-results-correct-path")

    // Scroll for missed evidence if present.
    app.swipeUp()
    RunLoop.current.run(until: Date().addingTimeInterval(0.4))
    capture(app, "27-results-scrolled")

    // Library filed state.
    if app.buttons["Put the phone down"].waitForExistence(timeout: 3) {
      app.buttons["Put the phone down"].tap()
      RunLoop.current.run(until: Date().addingTimeInterval(0.4))
    }
    if app.descendants(matching: .any)["library-back"].waitForExistence(timeout: 4) {
      let chip = app.descendants(matching: .any)["library-back"].firstMatch
      XCTAssertTrue(chip.isHittable, "library-back chip must be hittable")
      chip.tap()
    }
    if app.descendants(matching: .any)["case-library"].waitForExistence(timeout: 12) {
      capture(app, "28-library-after-filed")
    } else {
      // Still capture the post-results home if Cases chip is blocked — note in manifest.
      capture(app, "28-library-after-filed-fallback-home")
    }

    writeManifest()
  }

  // MARK: - Capture helpers

  private func capture(_ app: XCUIApplication, _ name: String) {
    // Brief settle so transitions finish before the shot.
    RunLoop.current.run(until: Date().addingTimeInterval(0.35))
    let shot = app.screenshot()
    let data = shot.pngRepresentation
    XCTAssertFalse(data.isEmpty, "empty screenshot for \(name)")
    let url = captureRoot.appendingPathComponent("\(name).png")
    do {
      try data.write(to: url, options: .atomic)
    } catch {
      XCTFail("failed to write \(url.path): \(error)")
    }
    let attachment = XCTAttachment(screenshot: shot)
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  private func waitFor(
    _ app: XCUIApplication, _ id: String, timeout: TimeInterval = 5,
    file: StaticString = #filePath, line: UInt = #line
  ) {
    let el = app.descendants(matching: .any)[id]
    XCTAssertTrue(
      el.waitForExistence(timeout: timeout),
      "expected accessibility id '\(id)' absent after \(timeout)s — refusing blank capture",
      file: file, line: line)
  }

  private func tap(
    _ app: XCUIApplication, _ id: String, timeout: TimeInterval = 5,
    file: StaticString = #filePath, line: UInt = #line
  ) {
    waitFor(app, id, timeout: timeout, file: file, line: line)
    let el = app.descendants(matching: .any)[id].firstMatch
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if el.isHittable {
        el.tap()
        return
      }
      RunLoop.current.run(until: Date().addingTimeInterval(0.15))
    }
    el.tap()
  }

  private func goHome(_ app: XCUIApplication) {
    for _ in 0..<12 {
      if isHome(app) { return }
      if hittableTap(app.descendants(matching: .any)["nav-home"]) { continue }
      if hittableTap(app.descendants(matching: .any)["nav-back"]) { continue }
      if hittableTap(app.descendants(matching: .any)["instagram-home"]) { continue }
      if hittableTap(app.descendants(matching: .any)["snapchat-home"]) { continue }
      if hittableTap(app.buttons["Home"]) { continue }
      if hittableTap(app.buttons["Back"]) { continue }
    }
    XCTAssertTrue(isHome(app), "failed to return home — navigation debt")
  }

  private func isHome(_ app: XCUIApplication) -> Bool {
    let messages = app.descendants(matching: .any)["app-messages"]
    return messages.waitForExistence(timeout: 1) && messages.firstMatch.isHittable
  }

  @discardableResult
  private func hittableTap(_ element: XCUIElement) -> Bool {
    guard element.exists, element.isHittable else { return false }
    element.tap()
    return true
  }

  private func sanitize(_ name: String) -> String {
    name.replacingOccurrences(of: " ", with: "-")
      .replacingOccurrences(of: "/", with: "-")
  }

  private func writeManifest() {
    let files =
      (try? FileManager.default.contentsOfDirectory(atPath: captureRoot.path))?
      .filter { $0.hasSuffix(".png") }.sorted() ?? []
    let text = """
      # Baseline capture manifest

      Device folder: \(captureRoot.lastPathComponent)
      Captured: \(ISO8601DateFormatter().string(from: Date()))
      Count: \(files.count)

      \(files.map { "- \($0)" }.joined(separator: "\n"))
      """
    try? text.write(
      to: captureRoot.appendingPathComponent("MANIFEST.md"),
      atomically: true,
      encoding: .utf8)
  }
}
