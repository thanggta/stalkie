# CARVE — Design Spec

**Status:** Approved for planning · **Date:** 2026-08-09
**Reframed 2026-08-12 — read §0.1 before anything else.**

> ## ⚠ 0.1 The premise and the scarcity model both moved (DR-10, then DR-11)
>
> **This document was written for a forensic-investigation game with a cycle budget.** Both are
> dead. The product is a relationship-suspicion drama: *you have your partner's unlocked phone.*
> Target player is a woman who has felt exactly that, not a detective or a puzzle enthusiast.
> Tone is jealousy and doubt — **no horror, no supernatural, no ARG.**
>
> | Built as | Now reads as |
> |---|---|
> | ~~Cycle budget~~ | **Removed (DR-11).** Free browsing; structure is discovery gates. |
> | Carving a fragment | Opening a thread, scrolling back, noticing a draft |
> | `hiddenUntil` | Something in one thread reveals another app, contact, or note |
> | `damage` / partial decode | Deleted and half-overwritten messages, recovered in pieces |
> | Filed verdict | ~15 concise questions, all required, scored on accuracy |
>
> **Where the old framing still shows, the framing is wrong.** Anything below that says
> "forensic workstation", "data-recovery technician", "device image", "cycle budget", or
> INV-1/INV-2 scarcity is superseded by this note, DR-8, DR-10, and DR-11.
>
> **Open, needs the owner:** the name. *File carving* is a forensic term, and the code is
> `CarveCore` / `CarveEngine` / `CarveCLI`. Renaming is mechanical but not free — flagged, not done.

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

**You are not solving a case. You are deciding what you believe about him.**

*Rewritten 2026-08-12 for DR-10 and DR-11. Two dead versions preceded this one: a contract
data-recovery technician examining client device images (DR-10 killed the premise), and a cycle
budget you spent to recover fragments (DR-11 killed the scarcity). Both are gone from the code.*

He left his phone on the counter. The shower is still running. You told yourself you wouldn't.

You browse it freely — every app opens, every thread is readable, nothing is behind a resource
bar. But the phone **opens further as you notice things**: a name in one thread makes another
thread mean something, a date in a note makes a photo matter. Some messages were deleted and
come back in pieces. Then you put it down and say what you think is true.

The verb is **browse → notice → decide.**

The last word is the one competitors don't have. They give you a phone and let you read it, and
then it just ends. Here you have to commit to an answer, on the record, about someone you love —
and you can be confidently, humiliatingly wrong.

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

*Rewritten 2026-08-12 for DR-11. The previous loop — ingest a sector map, spend cycles to carve
regions — is deleted, along with the solver and the budget that served it.*

```
  OPEN              NOTICE             CONNECT           FILE
  ────              ──────             ───────           ────
  His phone,    →   Something you  →   Work out      →   Answer all 15
  unlocked.         read opens         who is who,       questions.
  Browse           something          what happened     Scored on
  anything.         else                when             accuracy.
                          ↑                  │
                          └──────────────────┘
                        what you notice decides
                        what the phone shows next
```

1. **Open** — the phone is unlocked and yours. Every app on the home screen opens. Nothing costs
   anything. This is the fantasy, and competitors are right to give it away freely.
2. **Notice** — the phone **opens further as you read**. A `hiddenUntil` predicate on a fragment
   makes it appear once you have seen the thing that would have made you look for it. Structure
   comes from attention, not from a resource bar.
3. **Connect** — fragments go to a board where you draw connections: this number is that contact,
   this timestamp contradicts that story.
4. **File** — the ending. **15 concise questions, all of them required.** Scored on **accuracy,
   not completeness.**

### The rule that replaced scarcity

**Everything is readable. Not everything is visible yet.**

Gating is diegetic: you don't see the thread with Sable until you have seen the name Sable. That
is how noticing works in life, and it is why it doesn't feel like a designer withholding.

What this buys, now that the budget is gone:
- **Progress that feels like insight** rather than expenditure
- **Replay** — a second pass reaches things a first pass never opened
- **A reason to read carefully** instead of tapping exhaustively, because attention is the only
  thing that advances you

The forced verdict is what keeps this from being a reading app. Nearest relative is now *Her
Story* — free-form searching, no resource, an ending you have to commit to — rather than
*Papers, Please*'s constrained throughput.

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
| `damage` | Profile → shader params → rendered degraded asset | Metal render (DR-9) |
| `board` | Link graph state, player-drawn connections | domain models |
| `verdict` | Scores filed answers against the case answer key | domain models |
| `shell_ui` | The phone shell — iOS lookalike per DR-8, built as a swappable theme layer | all of the above |
| `entitlement` | Which case packs are owned | store SDK |

**`carve_engine` and `verdict` must stay pure** — no Flutter imports. They hold the actual
game rules, and they are the two modules where a bug silently corrupts play. Purity is what
makes them testable without a widget harness.

---

## 7. Design invariants

Testable properties. A violation is a bug, not a balance issue.

| ID | Invariant | Test |
|---|---|---|
| ~~INV-1~~ | ~~Every case is solvable with the cycles granted~~ | **Removed by DR-11** (no cycle budget) |
| ~~INV-2~~ | ~~No case can be fully recovered within budget~~ | **Removed by DR-11** (no cycle budget) |
| INV-3 | Every verdict question is answerable from fragments reachable through unlocks | Every `supportedBy` id exists and is in the unlock reachability set |
| INV-4 | No orphan fragments | Every fragment is on the sector map or reachable via `hiddenUntil` |
| INV-5 | Unlock rules are declarative data, never executable script | Schema validation rejects non-declarative rules |
| INV-6 | **Narrowed by DR-12.** Real *platform* brands allowed as in-game apps. No other real brand or trademark ships; no third party's actual asset files are bundled; every person is fictional | Asset review checklist per case |

Also hard-fail: **no unlock cycle** (A hidden until B, B hidden until A). INV-5 is a compliance
requirement — see `docs/compliance.md`.

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
| DR-10 | **Relationship-suspicion drama for women; drama tone, no horror.** "You have his phone." | Forensic investigation framing (the original premise); horror/supernatural framing (the genre default) | The audience doesn't respond, or playtests show the drama can't carry it without a genre hook |
| DR-11 | **Discovery-gated free browsing.** No cycle budget. Structure is `hiddenUntil`. Ending is a forced, scored verdict (~15 concise questions). | Cycle-budget scarcity (INV-1/INV-2); unscored ending; no ending | Playtests show free browsing without scarcity feels empty *and* discovery gates fail to replace it |
| DR-12 | **Real platform brands as in-game apps** — Instagram, Snapchat, Google Maps by name. Realism is the product. | Invented in-fiction brands (the genre's universal convention — Jabbr, Spark, Surfer); invented names held in a swappable config | Apple rejects at review, a rights-holder makes contact, or realism proves not to be what players are paying for |
| DR-13 | **Declarative `surface` routing** — fragments declare a stable surface id (`messages`, `photo_social`, `ephemeral_chat`, `maps`, …); brands map only through `PhoneAppLabels` | Hardcode routing on fragment ids/labels; scatter brand strings in case JSON | Surface grammar proves too coarse for a real case author |

### DR-13 — surface routing (app presentation)

**Decision (2026-08-12):** Keep medium types (`thread`, `image`, `note`, `record`) intact.
Add an optional declarative `surface` on every fragment. The shell hosts content by surface,
not by fragment id. Real platform display names stay in exactly one config file
(`PhoneAppLabels`). Case authors add Instagram / Snapchat / Maps evidence as data; unknown
surface values and illegal type×surface pairs fail validation.

This preserves the case definition of done: write JSON → `CarveCLI` → play. No Swift change
to author more social/location evidence once the surface is in the allowed set.

### DR-12 — the reasoning, and the exposure

**The bet:** what is being sold is *this is exactly what going through his phone feels like*. A
photo app called "Halo" is a game asset; Instagram is his actual life. The owner judges that the
recognition gap is where this genre's immersion leaks, and that closing it is worth the exposure.

**The exposure, plainly.** `docs/research-findings.md` §2 records 4.1(b) verbatim and verified:
it covers "in-game WhatsApp/Instagram/TikTok lookalikes" at **ASR & NR** — App Store Removal
*and* Developer Program Removal. This is the project's **second** account-removal trigger,
independent of the 5.2.5 one accepted in DR-8. Fixing either does not fix the other.

**Two asymmetries that make this heavier than DR-8:**

- **It is visible before install.** 5.2.5 exposure lives inside the app; a real logo shows up in
  the App Store screenshots. The realistic failure is rejection at review rather than removal
  later — so the practical risk is that it never ships at all.
- **The rights-holders are not the platform.** DR-8 accepted risk from Apple, who at least has
  a submission process to appeal within. Meta, Snap and Google are third parties with
  independent enforcement and no relationship to appeal to.

**One point in the decision's favour, recorded honestly:** `research-findings.md` line 164 notes
invented brands are "evidence of *convention*, not of legal necessity" — the research found no
source establishing that real brands must be avoided here. The 4.1(b) policy exposure is
verified; the trademark-law exposure is genuinely unestablished, not established-and-ignored.

**What DR-12 does NOT cover, and therefore still binds:**

- **No third party's actual asset files ship, ever.** Icons and wordmarks are drawn originally,
  even when drawn to be recognisable. Reproducing a mark is the trademark risk that was
  accepted; bundling Meta's PNG adds a clean, separate **copyright** claim for zero extra
  realism.
- **People stay fictional.** Real platforms do not come with real users. Every character,
  handle, number and photographed subject remains invented (rule 6).
- **Brand strings live in exactly one config file** — never scattered through views or case
  JSON. Reverting to invented names must cost a config edit, not a rewrite. This is the same
  retreat mechanism as DR-8's theme layer, and it is the only thing that makes DR-12 reversible.

### The app set (DR-12)

Derived from what the premise needs — the places people actually hide things — not from what is
cheap to build. Shapes already in the schema are marked.

| App | What it carries | Schema |
|---|---|---|
| Messages | the spine of the case | `thread` ✅ |
| Photos | what he kept, and what he deleted | `image` ✅ |
| Notes | drafts he never sent | `note` ✅ |
| Calls | who, when, how long | `record kind: call_log` ✅ |
| **Maps — location history** | the hardest evidence in the game: *he said he was at his brother's* | `record kind: location` ✅ |
| **Instagram** | DMs, follows, what he liked at 1am | new type needed |
| **Snapchat** | streaks and disappearing messages — *why her, every day* | new type needed |
| **Payments** | a transfer with no explanation | `record kind: transaction` ✅ |
| Browser history | what he searched at 2am | new type needed |
| Dating app | the smoking gun, if a case wants one | new type needed |

### DR-11 — the reasoning

The cycle budget was the original differentiator against free exhaustive browsing. After DR-8
and DR-10, the commercially validated titles on this shelf (*Normal Lost Phone* and kin) all
use free browsing with discovery structure — and they work. Scarcity was fighting the fantasy:
*his phone is right there* is not a resource-management fantasy.

**What replaces scarcity:** the six-predicate `hiddenUntil` grammar, already specified and
tested, now wired into load, visibility, and validation. Something she finds in one thread
opens another. Unlock cycles and unreachable gates are hard failures.

**What keeps a win condition:** the owner rejected both "no ending" and "unscored ending."
The case closes when she answers every verdict question (on the order of fifteen, concise
options). `fileVerdict` refuses incomplete filings; `scoreVerdict` grades accuracy. She can
still be wrong.

**Deleted with this record:** `cycleBudget`, `carveCost`, the INV-1 solver, INV-2, and the
off-premise `riverside` sample. Sample case is now `cases/five_minutes`.

### DR-10 — the reasoning

The forensic framing was chosen to solve Guideline 5.2.5 (§1), and DR-8 already abandoned that
solution. Once the shell is a phone, "you are a data-recovery technician examining a seized
drive" is a costume over a phone game — it adds an explanation the player has to accept before
she can feel anything.

The suspicion framing needs no explanation. Every player already knows what it is to want to
look. It also makes the scarcity mechanic *diegetic* rather than abstract: a cycle budget is a
game rule, but "he's in the shower" is a reason.

**Tone is drama, not horror, and this is a deliberate bet against the genre.** *Simulacra* and
most of the cluster reach for supernatural or serial-killer hooks because a believable failing
relationship is harder to write than a ghost. That difficulty is the moat. A player who finishes
a case thinking *"I've had that argument"* is worth more than one who finishes it startled.

**Consequences:**

- **Casting and content change, mechanics do not.** The engine, schema, invariants, and
  six-predicate grammar are untouched by this record. `riverside` is now off-premise content —
  it is a drowned-brother mystery — and should be re-authored or retired before it becomes the
  template every later case imitates.
- **The verdict question set carries the drama.** "Who did he meet" is a procedural question.
  "Is he leaving you", "did she know about you", "has this happened before" are the ones that
  land, and they are what makes being *wrong* hurt.
- **INV-6 and rule 6 matter more here, not less.** The closer the fiction sits to something a
  player recognises, the more important it is that every character, number, and handle is
  invented, and that the app never touches real device data.

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
  `docs/compliance.md` §3's comparison table. DR-11 then removed cycle-budget scarcity. What
  remains is discovery-gated structure, a forced filed verdict scored on accuracy, and the
  ability to be wrong. Those must be prominent in the first ten minutes of play and in the App
  Store screenshots, or there is no 4.3(b) answer left.
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
2. Surviving invariants INV-3…INV-6 enforced by automated tests (INV-1/INV-2 removed by DR-11)
3. Ships on iOS only (DR-9; Android removed from scope 2026-08-12)
4. ~~Zero simulated Apple interfaces, zero real brands~~ — **both reversed.** The shell simulates
   iOS (DR-8) and in-game apps carry real platform brands (DR-12). Two independent ASR & NR
   triggers, accepted knowingly. INV-6 survives only as: no *other* real brand, no bundled
   third-party asset files, every person fictional
5. A second case authorable **without an engineer** — the real test of the content pipeline

Item 5 is the one that decides whether this scales past one case. If authoring case 2 needs
code changes, the schema failed.
