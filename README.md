# CARVE

A narrative investigation game. You are a contract data-recovery technician: clients send you
damaged device images, you carve out what's recoverable, link the fragments, and file a verdict.

**You never have enough budget to recover everything.** That's the game.

> *File carving* is the real forensic term for recovering files from raw disk fragments when the
> filesystem metadata is gone.

---

## Status

**Core engine complete, nothing renders yet.** The game rules — domain models, six-predicate
unlock grammar, JSON loader, validator (INV-1…INV-4), solvability solver, carve engine, verdict
scoring — ship as a Swift package (`Sources/CarveCore`) with a validation CLI (`CarveCLI`).
The SwiftUI shell is the next phase.

> The directory is named `stalkie/` — that predates the concept, from when this began as
> research into cloning *Stalkie · Mobile Detective*. The project is CARVE and is deliberately
> not that app. No need to rename anything; just don't be confused by the path.

## Documents

| Doc | What it's for |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | **Start here if you're an agent.** Rules that override your defaults. |
| [`docs/superpowers/specs/2026-08-09-carve-design.md`](docs/superpowers/specs/2026-08-09-carve-design.md) | The design: core loop, damage system, architecture, decision records |
| [`docs/content-schema.md`](docs/content-schema.md) | Case bundle format. Enough to implement the loader from alone. |
| [`docs/compliance.md`](docs/compliance.md) | App Store constraints that override product preference |
| [`docs/superpowers/plans/2026-08-09-carve-core-plan.md`](docs/superpowers/plans/2026-08-09-carve-core-plan.md) | Task-by-task implementation plan for the core engine |
| [`docs/research-findings.md`](docs/research-findings.md) | Why the design is shaped this way, with evidence tags |

## The short version of why it's designed this way

Three findings from research drove every major decision:

1. **App Store Guideline 5.2.5 names this genre's core mechanic** — simulating an iOS home
   screen with a fake Messages app — at App Store *and* Developer Program removal severity. So
   CARVE's shell is a forensic workstation, not a phone. Nothing to argue about in review.

2. **Guideline 4.3(b) makes "meaningfully different" the submission bar**, not a marketing goal,
   in a category with ~18 near-identical entrants shipped in seven months. So the verb changed:
   competitors ship *free exhaustive browsing*; CARVE ships *constrained recovery with a win
   condition*.

3. **Asset production is the unbounded cost.** So damage is a runtime shader, not hand-made
   corrupted art. **The aesthetic is the budget** — a torn, half-decoded photo costs a fraction
   of convincing fake photography, and looks *more* real, because recovered data looks exactly
   like that.

## Stack

Swift / SwiftUI, iOS only, no backend. Content is static JSON bundles read locally. Damage
rendering is Metal (Plan 2). See DR-8/DR-9 in the design spec for the decision records.

## Getting started

```bash
swift build                                            # builds CarveCore + CarveCLI
swift test                                             # all suites (57 tests)
swift run CarveCLI cases/riverside                     # validate a case
```

The invariants (INV-1…INV-5) are enforced by tests and run against every case in CI
(`.github/workflows/ci.yml`).

## Non-negotiable

All fabricated personal content stays **fictional-character-only**. No feature reads real
contacts, photos, messages, or location; no feature accepts a phone number or handle to "look
up". See `docs/compliance.md` §7.
