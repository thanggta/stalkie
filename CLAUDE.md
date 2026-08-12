# CARVE — Agent Instructions

Read this before touching anything. It is the entry point for any AI agent or human joining
this project.

## What this is

**You have his phone. You don't have long.**

A relationship-suspicion drama. The player has her partner's unlocked phone and a limited window
before he's back. She reads what she can, pieces together what she finds, and decides what she
believes about him. Then she lives with that call.

### Who this is for

**Women who have felt this.** Not detectives, not hackers, not forensic analysts. The fantasy is
the one everybody recognises and nobody admits to: *his phone is right there and you have five
minutes.* Every design question resolves against her, not against a puzzle-game audience.

### Tone: drama, never horror

Jealousy, doubt, the sick feeling of being half-right. **No horror. No supernatural, no jump
scares, no dead-girlfriend twist, no ARG creepypasta.** The genre leans horror because it is
easier than writing a believable relationship — we are not taking that shortcut. The dread here
is entirely ordinary: he might be lying, or you might be about to blow up something real over
nothing.

### What makes it better than the competition

Same shelf as the rest of the genre, executed better. Three things they don't do
(`docs/compliance.md` §3), and since DR-8 made the shell an iOS lookalike, **these three now
carry the entire product differentiation by themselves:**

1. **You can never read everything.** A hard budget, and the case is authored so the budget
   cannot cover it (INV-2). Every tap costs you another one you'll never make.
2. **You have to decide.** The game ends in a filed verdict, scored on accuracy — not in
   "you've now read all the content."
3. **You can be wrong.** Confidently, and with consequences.

Everyone else ships free exhaustive browsing with no win condition and no way to lose.

### The one line that never moves

This is **fiction about fictional people**. No feature reads real contacts, photos, messages, or
location, and nothing accepts a real phone number or handle to look up. Rule 6 below, no
exceptions — it is what keeps this a game about a feeling rather than a tool for doing the thing.

## Read in this order

| # | Doc | Why |
|---|---|---|
| 1 | `docs/superpowers/specs/2026-08-09-carve-design.md` | The design. Start here. |
| 2 | `docs/content-schema.md` | The case format. Enough to implement `case_loader` alone. |
| 3 | `docs/compliance.md` | Constraints that override product preference |
| 4 | `docs/superpowers/plans/2026-08-09-carve-core-plan.md` | Execution plan, phased |
| 5 | `docs/research-findings.md` | Why the design is shaped this way |

## Stack

**Swift / SwiftUI, iOS only.** No backend. Content is static JSON bundles read from local
storage.

Changed on 2026-08-12 (DR-9). Flutter was chosen when Android was in scope; assumption A2
("iOS and Android both matter") was overturned in favour of iOS-only, which is the exact
condition DR-2 named for switching to SwiftUI. Damage rendering moves from Flutter fragment
shaders to Metal.

**Android is out of scope.** Do not add cross-platform abstractions for a port that is not
planned. If Android returns, it is a rewrite, and that cost was accepted knowingly.

---

## Rules that override your defaults

### 1. The iOS-lookalike shell is a deliberate, owner-accepted risk

**This rule was reversed on 2026-08-12. Earlier docs say the opposite — they are superseded,
not merely stale.** The shell is now an iOS lookalike: home-screen grid, system font, iOS
status bar, iMessage-style bubbles. See DR-8 in the design spec and `docs/compliance.md` §1.1.

The owner was shown the exposure — Guideline 5.2.5 is App Store Removal **and** Developer
Program Removal, and it names Messages explicitly — and chose this anyway. **Do not relitigate
it, do not water it down, and do not "helpfully" make the UI less iOS-like.** If you think it
is wrong, say so once and then build what was asked.

Three rules still bind, and these are not negotiable:

1. **Never ship Apple's artwork.** No copied icon files, logos, wordmarks, or glyph artwork.
   That is copyright and 4.1(c) — a different and worse problem than 5.2.5, and it is not
   covered by the accepted risk. Every asset is originally drawn.
2. **The visual language is a swappable theme layer.** Fonts, bubble geometry, corner radii,
   icon shapes, status-bar layout are data, not hardcoded constants. A reviewer flag must cost
   a reskin, not a rewrite.
3. **Fictional characters and brands only.** INV-6 is unchanged and unaffected. No real brand,
   logo, or trademark in any shipped asset.

### 2. Content is data, never script

Unlock rules use the fixed six-predicate grammar in `docs/content-schema.md` §4. Do not add an
expression evaluator, a scripting hook, or a "just a small `eval`". An expression evaluator is a
script interpreter wearing a hat, and it moves us to the wrong side of Guideline 3.3.2.

Adding a predicate requires a decision record in the design spec.

### 3. `CarveEngine` and `Verdict` stay pure

**No SwiftUI, no UIKit, no IO, no platform calls.** `Sources/CarveCore` imports `Foundation` and
nothing else — verify with `grep -rh "^import" Sources/CarveCore/`. These hold the actual game
rules and are the two modules where a bug silently corrupts play. Purity is what makes them
testable without booting a simulator, which is what keeps the suite fast. If you need a UI type
in one of them, the boundary is wrong — fix the boundary, don't import the framework.

The iOS app target depends on `CarveCore`. Never the reverse.

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

A non-engineer can author it end to end without touching Swift:

```
write case.json + fragments  →  swift run CarveCLI cases/<id>  →  play in harness  →  commit
```

If authoring a new case requires code changes, **the schema failed** — fix the schema, not the
case.

## Project state

**The core engine is complete as a Swift package** — 57 tests green, CI enforced
(`.github/workflows/ci.yml`), `swift run CarveCLI cases/riverside` exits 0. The Swift package
(`Sources/CarveCore`) is the SPM library target the iOS app will depend on: domain models,
the six-predicate grammar, Codable JSON loader, validator (INV-1…INV-4), exact solvability
solver, carve engine, verdict scoring, the `riverside` sample case, and the author-facing
`CarveCLI` validator. The Dart implementation that this ported was the reference; it is
deleted — `git` history at the Plan 1 commits (before 2026-08-12) is the record.

The port deliberately FIXED the Dart defects that were logged against Plan 1 rather than
reproducing them: Codable field-level parsing errors, strict `schemaVersion` integer checking,
value-type case/engine models, cast-free predicate parsing, canonical link keys, and a
Codable-restorable `CarveEngine`. `hiddenUntil` is still NOT implemented — it lands with the
link board (Plan 4), and v1 cases must not use it.

Nothing renders yet — the SwiftUI shell is Plan 3.
