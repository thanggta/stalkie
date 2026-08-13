# Design review artifacts

Baseline and after-redesign captures for CARVE UI/UX redesign.

| Path | Contents |
|---|---|
| `baseline/iPhone-17-Pro/` | Baseline simulator captures before redesign |
| `after/iPhone-17-Pro/` | Redesigned simulator captures matching baseline states |

## Capture environment & setup

- **Device / Runtime:** iPhone 17 Pro (iOS 26.5 simulator / Xcode 26)
- **State Setup:** Launch arguments `-resetProgress` and `-uiTestSkipRestore`
- **Harness:** `DesignBaselineCaptureUITests.swift` in `Apps/CarveUITests`

## Capture command

```bash
# Execute baseline / after capture suite on iPhone 17 Pro simulator
xcodebuild -project Apps/Carve.xcodeproj -scheme Carve \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath .build/DerivedData \
  -only-testing:CarveUITests/DesignBaselineCaptureUITests \
  CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY= test
```

## Before / After mapping

| # | Screen / State | Baseline | After Redesign |
|---|---|---|---|
| 01 | Case Library (not started) | `baseline/iPhone-17-Pro/01-library-not-started.png` | `after/iPhone-17-Pro/01-library-not-started.png` |
| 04 | Phone Home (initial) | `baseline/iPhone-17-Pro/04-home-initial.png` | `after/iPhone-17-Pro/04-home-initial.png` |
| 05 | Messages List | `baseline/iPhone-17-Pro/05-messages-list.png` | `after/iPhone-17-Pro/05-messages-list.png` |
| 09 | Home (Links unlocked) | `baseline/iPhone-17-Pro/09-home-links-visible.png` | `after/iPhone-17-Pro/09-home-links-visible.png` |
| 16 | Links Board (Entities) | `baseline/iPhone-17-Pro/16-links-with-entities.png` | `after/iPhone-17-Pro/16-links-with-entities.png` |
| 17 | Links Board (Node selected) | `baseline/iPhone-17-Pro/17-links-selected-node.png` | `after/iPhone-17-Pro/17-links-selected-node.png` |
| 18 | Links Board (Connection created) | `baseline/iPhone-17-Pro/18-links-completed-connection.png` | `after/iPhone-17-Pro/18-links-completed-connection.png` |
| 21 | Decide Intro | `baseline/iPhone-17-Pro/21-decide-intro.png` | `after/iPhone-17-Pro/21-decide-intro.png` |
| 22 | Decide Question | `baseline/iPhone-17-Pro/22-decide-question-section.png` | `after/iPhone-17-Pro/22-decide-question-section.png` |
| 22b | Decide Incomplete Warning | `baseline/iPhone-17-Pro/22b-decide-incomplete-validation.png` | `after/iPhone-17-Pro/22b-decide-incomplete-validation.png` |
| 24 | Decide Review | `baseline/iPhone-17-Pro/24-decide-review.png` | `after/iPhone-17-Pro/24-decide-review.png` |
| 25 | Decide Confirm | `baseline/iPhone-17-Pro/25-decide-confirm.png` | `after/iPhone-17-Pro/25-decide-confirm.png` |
| 26 | Verdict Results | `baseline/iPhone-17-Pro/26-results-correct-path.png` | `after/iPhone-17-Pro/26-results-correct-path.png` |
| 27 | Verdict Results Scrolled | `baseline/iPhone-17-Pro/27-results-scrolled.png` | `after/iPhone-17-Pro/27-results-scrolled.png` |

## Proof of correct screen capture

- The harness uses explicit `waitFor(app, accessibilityIdentifier)` assertions before every single capture step.
- If an accessibility identifier is missing or wrong, the harness immediately aborts with `XCTFail` ("refusing blank capture").
- Nondeterministic elements (status bar clock/battery, spring animation frames) settle via explicit `RunLoop.current.run(until:)` pauses before shot capture.
