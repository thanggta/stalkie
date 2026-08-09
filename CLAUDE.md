# CARVE — Agent Instructions

Read this before touching anything. It is the entry point for any AI agent or human joining
this project.

## What this is

A narrative investigation game. The player is a data-recovery technician who carves fragments
out of damaged device images, links them, and files a verdict. **Not** a phone simulator — that
distinction is a legal requirement, not a stylistic preference (see `docs/compliance.md` §1).

## Read in this order

| # | Doc | Why |
|---|---|---|
| 1 | `docs/superpowers/specs/2026-08-09-carve-design.md` | The design. Start here. |
| 2 | `docs/content-schema.md` | The case format. Enough to implement `case_loader` alone. |
| 3 | `docs/compliance.md` | Constraints that override product preference |
| 4 | `docs/superpowers/plans/2026-08-09-carve-plan.md` | Execution plan, phased |
| 5 | `docs/research-findings.md` | Why the design is shaped this way |

## Stack

Flutter (Dart), iOS + Android. No backend. Content is static JSON bundles read from local
storage.

Chosen because we render a *fictional* OS: we explicitly don't want platform widgets, and
Flutter's own renderer gives pixel-identical output everywhere plus the fragment shaders the
damage system needs. Rationale and rejected alternatives: design spec §6.2.

---

## Rules that override your defaults

### 1. Never simulate an Apple interface

Guideline 5.2.5 carries App Store Removal **and** Developer Program Removal severity, and it
names Messages explicitly. No iOS home-screen grids, no iMessage-style bubbles, no SF Pro, no
Apple emoji — including inside authored case content. `docs/compliance.md` §1 has the do/don't
table. **If a UI suggestion would look at home on an iPhone, it is wrong here.**

### 2. Content is data, never script

Unlock rules use the fixed six-predicate grammar in `docs/content-schema.md` §4. Do not add an
expression evaluator, a scripting hook, or a "just a small `eval`". An expression evaluator is a
script interpreter wearing a hat, and it moves us to the wrong side of Guideline 3.3.2.

Adding a predicate requires a decision record in the design spec.

### 3. `carve_engine` and `verdict` stay pure

No Flutter imports, no IO, no platform calls. They hold the actual game rules and are the two
modules where a bug silently corrupts play. Purity is what makes them testable without a widget
harness. If you need Flutter in one of them, the boundary is wrong — fix the boundary.

### 4. Never sell cycles

Cycles are a per-case design constant, not an IAP. Monetizing the resource that gates content is
pay-to-progress and invites the exact 3.1.2 scrutiny we designed around. Monetization is
one-time case-pack unlocks only.

### 5. Damage is a runtime shader, never a pre-made asset

`media/` holds clean sources only. Degradation comes from the fragment's `damage` block. This
is the design's central cost saving — one clean image serves every reveal state. Do not commit
a pre-corrupted PNG.

### 6. Fictional characters only

No feature reads real contacts, photos, messages, or location. No feature accepts a phone
number or handle to "look up". `docs/compliance.md` §7. This one has no exceptions.

---

## Working agreements

- **Match the existing style.** Conformance beats taste inside this codebase.
- **Surgical changes.** Touch what the task needs. Don't improve adjacent code.
- **State assumptions explicitly.** If two readings of a task lead to different work, say so.
- **Comment only where an expert would still need it.** Not line-by-line narration.
- **Fail loud.** "Done" is wrong if anything was skipped. "Tests pass" is wrong if any were
  skipped.
- **Surface conflicts, don't average them.** If two patterns contradict, pick the more tested
  one, explain why, flag the other.

## Testing

Tests encode *why* behavior matters, not just what it does. A test that can't fail when the
game rules change is not a test.

The design invariants (design spec §7) are the highest-value tests in the project:

| ID | Invariant |
|---|---|
| INV-1 | Every case is solvable within its cycle budget |
| INV-2 | No case is fully recoverable within budget |
| INV-3 | Every verdict question is answerable from carvable fragments |
| INV-4 | No orphan or unreachable fragments |
| INV-5 | Unlock rules are declarative data only |
| INV-6 | No real brand, logo, or trademark in any shipped asset |

INV-1 is proved by a **solver** that searches carve orderings — not by a human playing it.
Run every invariant in CI against every case.

## Definition of done for a case

A non-engineer can author it end to end without touching Dart:

```
write case.json + fragments  →  dart run tool/validate_case.dart cases/<id>  →  play in harness  →  commit
```

If authoring a new case requires code changes, **the schema failed** — fix the schema, not the
case.

## Project state

Greenfield. Docs exist; no code yet. Not a git repository — `git init` before the first commit.
