# CARVE — Design Spec

**Status:** Approved for planning · **Date:** 2026-08-09 · **Supersedes:** nothing

> **Working title: CARVE.** *File carving* is the real forensic term for recovering files from
> raw disk fragments when the filesystem metadata is gone. It names the mechanic, it's short,
> and it's ownable.

---

## 0. Assumptions I locked without asking

The brief said don't pause for questions. These are the calls I made and the evidence behind
each. **Every one is overturnable** — each is a numbered decision record in §8.

| # | Assumption | Basis |
|---|---|---|
| A1 | Solo developer, one title, not a portfolio of reskins | Empty greenfield repo; no team signals |
| A2 | iOS **and** Android matter (dev is Vietnam-based; Android dominates SEA) | Locale of the request |
| A3 | Shipping one polished title beats 12 cheap bets *for this developer* | Research §3: portfolio economics need portfolio scale |
| A4 | No prior Swift/Dart commitment | Empty repo |
| A5 | English first, localization later | Cheapest path to first ship |

---

## 1. The problem this design solves

Three findings from `docs/research-findings.md` constrain everything:

1. **Guideline 5.2.5 names this genre's core mechanic.** Simulating an iOS home screen with a
   fake Messages app is the one thing Apple explicitly prohibits, at ASR & NR severity. The
   genre's standard workaround — invented in-fiction brand names — does not touch this.
2. **Guideline 4.3(b) makes "meaningfully different" the submission bar,** not a marketing
   goal, in a category with ~18 near-identical entrants.
3. **Asset production is the unbounded cost.** Reference apps ship 84.7 MB and 177 MB. Nothing
   in the research established what a case actually costs to produce — the highest-priority
   question returned nothing. That's an unknown we must design *around*, not estimate.

A design that only avoids the iPhone shell solves #1 and half of #2. It does nothing for #3.

---

## 2. The core idea

**You are not browsing a phone. You are recovering a damaged one.**

The player is a contract data-recovery technician. Clients send device images that are
corrupted, partially overwritten, water-damaged, or deliberately wiped. You carve out what's
recoverable, cross-reference the fragments, and file a conclusion.

The verb changes from **browse** to **allocate under scarcity, then infer**.

### Why this specific reframe

It is the only concept I found that resolves all three constraints with one move:

| Constraint | How the reframe resolves it |
|---|---|
| 5.2.5 — no Apple lookalike | ~~The shell is a desktop-style forensic workstation. It resembles no Apple product, interface, or app. Nothing to argue about.~~ **No longer true — overturned by DR-8 on 2026-08-12. This constraint is now knowingly unresolved and carried as accepted risk.** The reframe below still resolves the other two. |
| 4.3(b) — meaningfully different | Every competitor ships *free exhaustive browsing*. This ships *constrained recovery with a win condition*. Different verb, different loop, different failure state. |
| Asset cost — the unbounded one | **Degraded assets are cheaper to produce than pristine ones.** A torn, half-decoded, block-corrupted photo costs a fraction of convincing fake photography — and it is *more* convincing, because real recovered data looks exactly like that. |

That third row is the design's actual thesis. **The aesthetic is the budget.** In every other
title in this genre, fidelity of fabrication is the cost center. Here, damage is the art
direction, and damage is cheap.

### The secondary win: fragmentation becomes diegetic

The genre's chronic writing problem is *"why can't I just read everything immediately?"* —
answered elsewhere with arbitrary locked albums and passcode busywork. Here the answer is
structural: **the data is damaged.** Gating stops feeling like a designer withholding and
starts feeling like the premise.

---

## 3. Core loop

```
  INGEST            CARVE              LINK              FILE
  ──────            ─────              ────              ────
  Load device   →   Spend cycles   →   Connect       →   Answer the
  image; see        to recover         fragments on      client's
  a sector map      fragments          a board           questions
  of unknown        (messages,         (timeline +
  recoverable       photos, notes,     relationships)
  regions           call logs)
                          ↑                  │
                          └──────────────────┘
                        new fragments suggest
                        where to spend next
```

1. **Ingest** — the case opens on a *sector map*: a grid of recoverable regions, each showing
   only a type hint and an integrity score. You don't know what's in them.
2. **Carve** — spending **cycles** (the scarce resource) recovers a region. Low-integrity
   regions cost more and come back partial.
3. **Link** — recovered fragments go to a board where you draw connections: this number is
   that contact, this photo timestamp contradicts that alibi.
4. **File** — the win condition. The client asks 3–6 specific questions. You answer. You are
   scored on **accuracy, not completeness.**

### The scarcity rule

**You always have enough cycles to answer correctly. You never have enough to recover
everything.** (Design invariant — see §7.)

This is the whole game. It produces:
- Real decisions (competitors have none — you just read everything)
- Replay value (a second pass finds a different half)
- Post-play conversation ("did you find the voicemail?")
- A reason to *think* rather than exhaustively tap

Nearest relatives: *Return of the Obra Dinn*'s verdict-based scoring, *Papers, Please*'s
constrained throughput.

### What is explicitly NOT in the design

YAGNI, ruthlessly:

- ❌ **No selling cycles.** Monetizing the resource that gates content is pay-to-progress and
  invites exactly the 3.1.2 "tricking users" scrutiny we're avoiding. Cycles are a per-case
  design constant. Not an IAP. Ever. (See §8, DR-5.)
- ❌ No multiplayer, no accounts, no cloud save at v1
- ❌ No procedural case generation — cases are hand-authored, that's the product
- ❌ No real-time pressure or timers
- ❌ No minigames (lockpicking, hacking puzzles)

---

## 4. Content model

Five fragment types cover every case. Adding a sixth requires a decision record.

| Type | What it is | Production cost |
|---|---|---|
| `thread` | A message conversation, partially recovered | Low — text |
| `image` | A photo, degraded by a named damage profile | **Low** — see §5 |
| `note` | Free text: notes, drafts, documents | Low — text |
| `record` | Structured rows: call log, location pings, transactions | Low — data |
| `audio` | Voice memo or call fragment | High — defer past v1 |

`audio` is specified but **not built in v1.** It's the only expensive type; ship without it,
add it when a case genuinely needs one.

---

## 5. The damage system — where the money is saved

Every degraded asset is produced by applying a **damage profile** to a clean source at build
time (or at runtime, via shader). Profiles are named, reusable, and declared in content:

| Profile | Visual | Implementation |
|---|---|---|
| `block-loss` | Missing 8×8 blocks, JPEG-style | Runtime shader |
| `scanline-tear` | Horizontal displacement bands | Runtime shader |
| `partial-decode` | Bottom N% is noise — the classic half-loaded JPEG | Runtime shader |
| `chroma-bleed` | Color channels desynced | Runtime shader |
| `overwrite` | Foreign data bleeding through | Runtime shader |

**This is the single highest-leverage engineering decision in the project.** Because damage is
applied *at runtime from a declared profile*, one clean source image yields many distinct
recovered states — including progressive reveal as the player spends more cycles on the same
fragment. Authors write `damage: partial-decode 0.6`, not a hand-made corrupted PNG.

Consequences:
- Asset count drops by roughly the number of degradation states we'd otherwise author
- Binary size drops (no duplicate damaged variants)
- Damage intensity becomes a *gameplay* variable, tunable without touching art
- The look is consistent because it's one shader family, not hand-work

---

## 6. Architecture

### 6.1 Read/write model (required before any implementation proposal)

| Question | Answer |
|---|---|
| Who writes, how often, through what path? | 1–2 authors, offline, one case every few weeks. Authoring → validator → static bundle. |
| Who reads, how often, acceptable latency? | Every player, on-device, at frame latency, entirely local during play. |
| Bounded or unbounded? | Bounded and small per case (text + a few MB of media). Grows slowly by appending cases. |

**→ No backend for gameplay.** Content ships as static bundles read from local storage.

The junior mistake being avoided: building an API or database for content that never mutates at
runtime. This data is written once by us and read thousands of times by a device that already
has it. The cheapest cache is the file itself.

Server scope is exactly two things, both optional at v1:
1. Static bundle hosting on a CDN for post-launch cases
2. Receipt validation, if we ever need server-side entitlement

### 6.2 Stack

**Flutter.**

> **⚠ OVERTURNED 2026-08-12 by DR-9 — the stack is now Swift / SwiftUI, iOS only.** The whole
> argument below rested on two premises that no longer hold: that we are building a *fictional*
> OS (DR-8 replaced it with an iOS lookalike), and that Android is in scope (A2 overturned).
> Note the inversion: because the shell now deliberately *does* imitate the platform, native
> widgets stopped being a liability and became an asset. The rejection note under SwiftUI below
> names this exact condition and says "switch" — which is what happened. Retained as the record
> of why Flutter was right at the time.

The usual argument says native wins on UI fidelity. **This project inverts it.** We are
building a *fictional* OS — we explicitly do not want platform widgets, and we want identical
rendering everywhere, because the interface is a designed artifact, not a native experience.
Flutter draws every pixel with its own renderer (Impeller). That stops being a cross-platform
compromise and becomes the actual fit.

Supporting reasons: one codebase for iOS + Android (A2), fragment shader support for the damage
system (§5), strong custom-paint and animation story.

Rejected:
- **SwiftUI** — genuinely excellent for this UI, smallest binary, native StoreKit 2. Rejected
  only on A2 (Android is a full rewrite). *If A2 is wrong and this is iOS-only, switch.*
- **Unity** — the genre precedent (*Simulacra*), but wrong here: heavy baseline binary, painful
  text/scroll UI, and we have no 3D or VFX to justify it.
- **React Native** — no advantage over Flutter for pixel-precise custom UI; weaker shader story.

### 6.3 Content format — not Ink, and not primarily because of the runtime gap

**Own JSON schema.** Full spec in `docs/content-schema.md`.

The architectural reason comes first: Ink is built for **branching narrative flow.** This game
is **non-linear exploration of a static corpus** — threads, galleries, logs, notes — plus
declarative unlock gates. Different shape. Adopting Ink means taking on a compiler and runtime
version-lock coupling for branching we'd barely use.

The runtime gap confirms it rather than driving it: inkle ships C# and JavaScript runtimes only.
On Flutter we'd depend on a community Dart port of unknown maturity.

**Revisit Ink only if** a case genuinely needs deep branching dialogue (e.g. a live
interrogation scene). Until then it is speculative complexity.

### 6.4 Module boundaries

Each unit has one purpose, a defined interface, and is independently testable.

| Module | Does | Depends on |
|---|---|---|
| `case_loader` | Reads + validates a case bundle → domain objects | schema only |
| `carve_engine` | Cycle budget, carve costs, reveal state. **Pure, no UI, no IO.** | domain models |
| `damage` | Profile → shader params → rendered degraded asset | Flutter render |
| `board` | Link graph state, player-drawn connections | domain models |
| `verdict` | Scores filed answers against the case answer key | domain models |
| `shell_ui` | The fictional workstation UI | all of the above |
| `entitlement` | Which case packs are owned | store SDK |

**`carve_engine` and `verdict` must stay pure** — no Flutter imports. They hold the actual
game rules, and they are the two modules where a bug silently corrupts play. Purity is what
makes them testable without a widget harness.

---

## 7. Design invariants

Testable properties. A violation is a bug, not a balance issue.

| ID | Invariant | Test |
|---|---|---|
| INV-1 | Every case is solvable with the cycles granted | Solver test: optimal path answers all questions within budget |
| INV-2 | No case can be fully recovered within budget | Sum of all carve costs > budget, asserted per case |
| INV-3 | Every verdict question is answerable from carvable fragments | Every answer key entry traces to ≥1 reachable fragment |
| INV-4 | No orphan fragments | Every fragment is reachable from the initial sector map |
| INV-5 | Unlock rules are declarative data, never executable script | Schema validation rejects non-declarative rules |
| INV-6 | No real brand, logo, or trademark in any shipped asset | Asset review checklist per case |

INV-1 and INV-2 together *are* the scarcity rule (§3). INV-5 is a compliance requirement — see
`docs/compliance.md`.

---

## 8. Decision records

| ID | Decision | Alternative rejected | Overturn if… |
|---|---|---|---|
| ~~DR-1~~ | ~~Forensic recovery console, not a phone shell~~ | **OVERTURNED 2026-08-12 by DR-8.** | — |
| ~~DR-2~~ | ~~Flutter~~ | **OVERTURNED 2026-08-12 by DR-9**, via the exact condition this record named. | — |
| DR-3 | Own JSON schema, no Ink | Ink for all content | A case needs deep branching dialogue |
| DR-4 | Runtime damage shaders | Pre-authored damaged assets | Shader work proves harder than the asset savings justify |
| DR-5 | One-time IAP per case pack; case 1 free and complete | Weekly subscription (genre standard) | You accept paywall review risk for the 8.9% tail — but see §9 |
| DR-6 | No `audio` fragments in v1 | Ship all five types | A case's core reveal genuinely requires voice |
| DR-7 | English only at v1 | 6 languages like Stalkie | After first case validates, localization is real leverage |
| DR-8 | **iOS-lookalike shell** — home grid, system font, iOS status bar, iMessage-style bubbles | Forensic workstation (the original DR-1, zero 5.2.5 exposure); fictional phone OS (phone-shaped and immersive, own visual language, near-zero 5.2.5 exposure) | A reviewer flags 5.2.5, or you decide the account risk outweighs the familiarity gain |
| DR-9 | **Swift / SwiftUI, iOS only**; damage via Metal | Flutter (the original DR-2, retains Android) | Android returns to scope — and note that is a rewrite, not a recompile |

### DR-8 — the reasoning, stated honestly

Chosen for maximum player familiarity and immersion. The owner was shown that Guideline 5.2.5
carries App Store Removal **and** Developer Program Removal, that it names Messages explicitly,
and that this shell is the precise configuration it describes. The owner was also shown the
middle option — a fictional phone OS that keeps the phone-shaped intimacy while resembling no
Apple product — and rejected it in favour of the full lookalike.

**This is an accepted business risk owned by the project owner, not an engineering oversight.**
It is recorded here so no future contributor mistakes it for one and "fixes" it.

Two consequences follow, and both are load-bearing:

- **§4.3(b) differentiation gets weaker.** "Phone shell" was one of the four differentiators in
  `docs/compliance.md` §3's comparison table. The remaining three — cycle budget, filed verdict
  scored on accuracy, and never enough budget to see everything (INV-2) — now carry the whole
  differentiation argument alone. They must be prominent in the first ten minutes of play and
  in the App Store screenshots, or there is no 4.3(b) answer left.
- **The theme layer is the retreat plan.** Fonts, bubble geometry, radii, icon shapes and
  status-bar layout ship as data, never as hardcoded constants. If this is not built, a 5.2.5
  flag means a rewrite instead of a reskin, and DR-8 becomes irreversible in practice.

Apple's own artwork is never shipped under any circumstance — copied icons, logos, wordmarks or
glyph artwork are copyright and 4.1(c), which DR-8 does **not** cover.

---

## 9. Monetization

**Case 1 free and complete. Further cases as one-time IAP packs. No subscription.**

Rationale, from research:
- Premium one-time is **the only model validated in this genre** by surviving evidence
  (*A Normal Lost Phone*, ~200k units at €2.99–5.99)
- It sidesteps the paywall-presentation risk that 3.1.2 actually polices
- The subscription tail (8.9% to $10K MRR) is a *portfolio* return, and A3 says we're not
  running a portfolio

A free, complete first case is also the strongest possible 4.3(b) answer: a reviewer can play
the whole differentiated loop without paying.

---

## 10. What "done" means for v1

1. One complete case, free, start to filed verdict, ~45–90 minutes
2. All five invariants INV-1…INV-6 enforced by automated tests
3. Ships on iOS only (DR-9; Android removed from scope 2026-08-12)
4. Zero simulated Apple interfaces, zero real brands (INV-6)
5. A second case authorable **without an engineer** — the real test of the content pipeline

Item 5 is the one that decides whether this scales past one case. If authoring case 2 needs
code changes, the schema failed.
