# CARVE

A relationship-suspicion drama. You have his unlocked phone. You browse freely; the phone opens
further as you find things. Then you answer for what you believe — and you can be wrong.

---

## Status

**Core engine and the damage renderer are complete; the game shell is next.** The game rules —
domain models, six-predicate unlock grammar wired into `hiddenUntil`, JSON loader, validator
(INV-3…INV-5 + unlock-cycle detection), discovery-gated carve engine, forced complete verdict
scoring — ship as a Swift package (`Sources/CarveCore`) with a validation CLI (`CarveCLI`). The
five damage profiles render as deterministic Metal shaders (`Sources/CarveDamage`). The SwiftUI
shell is the next phase.

Sample case: `cases/five_minutes` (ordinary relationship drama; no horror).

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

## Stack

Swift / SwiftUI, iOS only, no backend. Content is static JSON bundles read locally. Damage
rendering is Metal. See DR-8/DR-9/DR-11 in the design spec.

## Getting started

```bash
swift build                                            # builds CarveCore + CarveDamage + CarveCLI
swift test                                             # all suites
swift run CarveCLI cases/five_minutes                  # validate a case
```

The invariants (INV-3…INV-5) are enforced by tests and run against every case in CI
(`.github/workflows/ci.yml`).

## Non-negotiable

All fabricated personal content stays **fictional-character-only**. No feature reads real
contacts, photos, messages, or location; no feature accepts a phone number or handle to "look
up". See `docs/compliance.md` §7.
