# CARVE

A relationship-suspicion drama. You have his unlocked phone. You browse freely; the phone opens
further as you find things. Then you answer for what you believe — and you can be wrong.

---

## Status

**Playable foundation is in place on iOS.** `CarveCore` holds pure game rules (six-predicate
unlocks, discovery-gated browsing, forced complete verdict scoring). `CarveDamage` renders
deterministic Metal degradation from clean sources. `CarveShell` owns themes, case loading,
the production catalog, and versioned session persistence. `CarveCommerce` owns StoreKit 2
one-time entitlements. `CarveUI` is an iOS-lookalike phone shell plus a game-layer case
library. Progress is per-case and survives process death.

Cases: `cases/five_minutes` is free and complete. `cases/dont_wait_up` is the first paid-case
candidate (observed internal playtime 32 minutes — not commercially polished). The library
is `cases/catalog.json`. Product IDs live only there.

> The directory is named `stalkie/` — that predates the concept. The project is CARVE.

## Documents

| Doc | What it's for |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | **Start here if you're an agent.** Rules that override your defaults. |
| [`docs/superpowers/specs/2026-08-09-carve-design.md`](docs/superpowers/specs/2026-08-09-carve-design.md) | The design: core loop, damage system, architecture, decision records |
| [`docs/content-schema.md`](docs/content-schema.md) | Case bundle format. Enough to implement the loader from alone. |
| [`docs/compliance.md`](docs/compliance.md) | App Store constraints that override product preference |
| [`docs/superpowers/plans/2026-08-09-carve-core-plan.md`](docs/superpowers/plans/2026-08-09-carve-core-plan.md) | Task-by-task implementation plan for the core engine |
| [`docs/research-findings.md`](docs/research-findings.md) | Why the design is shaped this way, with evidence tags |
| [`docs/storekit.md`](docs/storekit.md) | Local StoreKit testing and App Store Connect product setup |
| [`docs/accessibility.md`](docs/accessibility.md) | Accessibility baseline and manual VoiceOver checks |

## Stack

Swift / SwiftUI, iOS only, no backend. Content is static JSON bundles read locally. Damage
rendering is Metal. See DR-8/DR-9/DR-11 in the design spec.

## Getting started

```bash
swift build                                            # package targets
swift test                                             # all suites
swift run CarveCLI cases/five_minutes                  # validate a case
swift run CarveCLI --catalog cases/catalog.json        # validate the production library
swift build --target CarveUI                           # phone shell typecheck
xcodebuild -project Apps/Carve.xcodeproj -scheme Carve \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build                        # iOS app
```

The invariants (INV-3…INV-5) are enforced by tests and run against every case in CI
(`.github/workflows/ci.yml`).

## Non-negotiable

All fabricated personal content stays **fictional-character-only**. No feature reads real
contacts, photos, messages, or location; no feature accepts a phone number or handle to "look
up". See `docs/compliance.md` §7.
