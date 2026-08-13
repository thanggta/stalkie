# CARVE — UI/UX Audit (baseline)

**Date:** 2026-08-13  
**Branch:** `ui-ux-redesign`  
**Base commit:** `c4a085a`  
**Method:** Code review of all `Sources/CarveUI` + theme/layout in `CarveShell`, internal playtests (`cases/*/PLAYTEST.md`), HIG cross-check (navigation, 44pt targets, Dynamic Type, VoiceOver, feedback), simulator baseline capture (`design-review/baseline/`, DesignBaselineCaptureUITests).

**Constraints preserved:** DR-8 iOS-lookalike shell; DR-12 real platform names; free complete first case; one-time IAP; fictional people only; six-predicate unlocks; no game rules in views.

---

## How to read this document

| Category | Meaning |
|---|---|
| **Usability** | Player cannot complete a primary task, or does so only with guesswork |
| **Accessibility** | VO, Dynamic Type, Reduce Motion, color-only, targets |
| **Visual quality** | Inconsistent craft, optical weight, hierarchy |
| **Emotional pacing** | Drama / consequence under-delivered |
| **Intentional fiction** | Differs from utility-app norms **on purpose** — not a defect |

Severity: **Critical** · **Important** · **Moderate** · **Minor**

---

## Cross-product findings

### X-1 · Home is a dense equal-weight grid  
**Severity:** Important · **Type:** Usability + Visual + Emotional  
**Evidence:** `HomeScreenView.pageOrder` places ~24 apps; `pageApps` truncates by `maxPageIcons` but every visible icon shares equal size/weight. Decorative apps (Stocks, Podcasts, HomeKit…) compete with Messages and with diegetic **Links** / **Decide**. Playtests: “Links and Decide sit on the home screen like cheats.”  
**User consequence:** Player opens Calendar/Mail/Settings by habit; misses Links (only path to Maps gate); Decide feels bolted on.  
**Correction:** Reduce filler prominence (second page, lower opacity, or intentional empty states for a smaller set). Give Links/Decide a diegetic entrance moment (badge + banner + optional dock-adjacent placement when unlocked). Prefer declarative home layout data later if cases need different grids — **no `caseId` branches**.  
**Affects:** theme, navigation, possibly schema (home layout), tests.

### X-2 · Navigation hit-testing is fragile  
**Severity:** Important · **Type:** Usability  
**Evidence:** `FullLoopUITests.goHome` and baseline capture use coordinate force-taps for `nav-home` / stacked `NavigationStack` chrome. Comment in test: “common with stacked NavigationStack + overlay chrome.” Status bar / Cases chip / banners overlay the stack.  
**User consequence:** Missed taps, double-backs, stuck in apps; tests paper over real hit-test debt.  
**Correction:** Single nav chrome owner; overlays must not steal taps except intentional controls; ensure back/home are always hittable without coordinates. Fix views first; then remove force-tap workarounds from tests.  
**Affects:** navigation, tests.

### X-3 · Discovery feedback channels compete  
**Severity:** Important · **Type:** Usability + Emotional  
**Evidence:** Unlock banners (`UnlockBannerStack`, auto-dismiss 3.5s), app badges (`badgeCount`), “NEW” chips on rows, newly appearing home icons (Links/Decide), Maps content appearing after link — no single hierarchy.  
**User consequence:** Player may dismiss banner without reading, miss badge, never open Links, never understand why Maps changed.  
**Correction:** One hierarchy: (1) banner for *new app* or *high-stakes unlock*, (2) badge for *unread in app*, (3) in-list NEW for *row*, (4) subtle home attention only for Links/Decide first appearance. Banner copy should name the change without quest-log language.  
**Affects:** UI, session notices, tests.

### X-4 · Theme fonts use fixed point sizes  
**Severity:** Important · **Type:** Accessibility  
**Evidence:** `ThemeFonts` + `Font.system(size:)` in `Color+Theme.swift`; `docs/accessibility.md` already notes incomplete Dynamic Type.  
**User consequence:** AX text sizes clip or leave hierarchy broken; verdict/library may become unreadable.  
**Correction:** Map theme tokens to text styles with relative scaling; reflow library cards and verdict options at AX3+; never “fix” by truncating prompts.  
**Affects:** theme, accessibility, tests.

### X-5 · Case library is a functional list, not a game layer  
**Severity:** Important · **Type:** Visual + Emotional + Usability  
**Evidence:** `CaseLibraryView` — “Cases” title, equal cards, Restore + Delete all progress at same visual weight as play. Progress is caption text only. Replay sits beside Open.  
**User consequence:** Feels like a settings/catalog prototype; destructive actions compete with play; Free/Locked/Owned/Filed do not scan at a glance.  
**Correction:** Distinct game-layer identity (darker/quieter chrome vs phone white); primary CTA hierarchy; demote restore/delete into a secondary menu; state chips for Free / Locked / Owned / In progress / Filed.  
**Affects:** UI, theme tokens for game layer, tests.

### X-6 · Decide is a multi-question form  
**Severity:** Important · **Type:** Emotional pacing + Usability  
**Evidence:** `VerdictFlowView` sections of five cards in a scroll; progress is `n/total` + thin bar; intro is strong copy but middle is survey-like. Playtest: after affair is obvious, last stretch is “scoring, not discovery.”  
**User consequence:** Filing loses weight; 15 questions feel like a form to clear.  
**Correction:** Keep all 15 required. Improve focus (one question emphasis, calmer section transitions), stronger review, heavier confirm. No fake urgency/countdowns.  
**Affects:** UI only (no rule change).

### X-7 · Results report accuracy but rarely re-interpret evidence  
**Severity:** Important · **Type:** Emotional pacing  
**Evidence:** `VerdictResultsView` — wrong cards show “You said / It was”; right rows list prompts; missed fragments list labels. No case-authored “why this was fair to get wrong” unless added to schema.  
**User consequence:** Ending feels like a quiz key, not the emotional landing.  
**Correction:** Optional declarative `rationale` / `evidenceHint` on questions or results in case JSON; validate; never invent prose from right/wrong counts in Swift.  
**Affects:** schema (if adopted), content, UI, tests.

### X-8 · Icon craft is uneven  
**Severity:** Moderate · **Type:** Visual quality  
**Evidence:** AppIcons masters range ~668B (`ephemeral_chat`) to ~47KB (`photo_social`); optical weight and finish inconsistent. Marketing AppIcon is generic vs premise.  
**User consequence:** Shell reads as prototype; platform apps less believable (DR-12 risk without better original marks).  
**Correction:** Single construction grid, depth, corner treatment; redraw thin icons; app icon communicates “unlocked phone / private life” without Apple artwork.  
**Affects:** assets, theme.

### X-9 · Empty apps are dead ends  
**Severity:** Moderate · **Type:** Usability + Fiction  
**Evidence:** `EmptyShellAppView` — “No content.” Playtests tried Calendar/Mail/Safari and wanted believable empty states.  
**User consequence:** Breaks “his phone” fantasy; teaches player only a few apps matter (which can help or hurt).  
**Correction:** Per-app empty copy (Calendar “No Events”, Mail inbox empty) via theme or small string table — not case-authored spam. Keep most fillers empty intentionally.  
**Affects:** UI, copy.

### X-10 · Page dots imply a second page that does not exist  
**Severity:** Minor · **Type:** Visual / Usability  
**Evidence:** `pageDots` always draws two dots; only one page of icons.  
**User consequence:** Players swipe for a second page that isn’t there.  
**Correction:** One dot until multi-page is real; or implement page 2 for low-priority apps.  
**Affects:** home layout, tests.

---

## Screen-by-screen

### Case library

| ID | Finding | Sev | Type | Correction | Affects |
|---|---|---|---|---|---|
| L-1 | Title “Cases” + thin subtitle — no brand/mood | Important | Visual/Emotional | Game-layer masthead; premise line; artwork-forward cards | UI, theme |
| L-2 | Free/Locked/Owned only in caption + accent color | Important | Usability | State chip + CTA label (Open / Continue / Buy / Filed) | UI |
| L-3 | Delete all progress equal weight to Restore | Important | Usability | Overflow / “Manage” secondary | UI |
| L-4 | Filed still says “Continue” as primary | Moderate | Usability | “Review verdict” when filed | UI |
| L-5 | StoreKit unavailable copy only on purchase path | Moderate | Usability | Library shows Unavailable clearly on paid card | UI |

### Purchase

| ID | Finding | Sev | Type | Correction | Affects |
|---|---|---|---|---|---|
| P-1 | Plain scroll form; correct legal copy but no case art | Moderate | Visual | Artwork + case title hierarchy; keep one-time / not subscription / restore | UI |
| P-2 | Cancel copy is good (“Nothing was charged”) | — | Intentional | Keep | — |

### Home

| ID | Finding | Sev | Type | Correction | Affects |
|---|---|---|---|---|---|
| H-1 | Equal-weight overcrowding | Important | See X-1 | Filler demotion / page 2 | home, schema? |
| H-2 | Links/Decide appear as normal icons | Important | Usability/Emotional | First-appear attention treatment | UI |
| H-3 | Weather widget is decorative noise | Moderate | Visual | Keep for fiction or shrink; don’t compete with dock | UI |
| H-4 | `maxPageIcons` truncates without affordance | Important | Usability | Never drop Messages/Notes/critical apps; overflow page | layout, tests |
| H-5 | Fake second page dots | Minor | See X-10 | Fix dots | UI |

### Messages / Notes / Phone / Photos

| ID | Finding | Sev | Type | Correction | Affects |
|---|---|---|---|---|---|
| M-1 | Messages list is strongest surface (large title, rows) | — | Positive | Keep pattern as reference for other apps | — |
| M-2 | Photos grid lacks a11y identifiers | Important | Accessibility | `photos-item-{id}` + labels | UI, tests |
| M-3 | Photos show SF placeholder, not damaged thumb | Moderate | Visual/Emotional | Show damaged thumbnail from runtime damage | UI, damage |
| M-4 | Notes/Phone are functional lists | Moderate | Visual | Align chrome with Messages quality | UI |

### Maps / Instagram / Snapchat

| ID | Finding | Sev | Type | Correction | Affects |
|---|---|---|---|---|---|
| S-1 | Platform apps are recognizable (DR-12 intentional) | — | Intentional fiction | Keep real names; original icons only | — |
| S-2 | Maps before gate may look empty/confusing | Important | Usability | Empty state: “No Significant Locations” until unlock, then clear new pin | UI |
| S-3 | Instagram/Snapchat chrome is dense; OK if content is clear | Moderate | Visual | Polish, don’t redesign brands away | UI |

### Links

| ID | Finding | Sev | Type | Correction | Affects |
|---|---|---|---|---|---|
| K-1 | Instruction banner is tutorial-y but needed | Moderate | Usability | Shorter diegetic line; teach by selection state | UI |
| K-2 | Nodes are capsules on a blank canvas; scales poorly | Important | Usability/Visual | Suspicion-board layout; clear edges; list of connections | UI |
| K-3 | No VoiceOver announcement when link unlocks content | Important | Accessibility | Accessibility notification or banner when phone changes | UI |
| K-4 | Self/duplicate links guarded in session | — | Positive | Keep | — |

### Decide / Results

| ID | Finding | Sev | Type | Correction | Affects |
|---|---|---|---|---|---|
| D-1 | Intro copy is strong | — | Positive | Keep tone | — |
| D-2 | Section = five stacked cards = form | Important | See X-6 | Focus + pacing | UI |
| D-3 | Incomplete validation is plain red text | Moderate | Usability | Anchor near Next; gentle shake optional (Reduce Motion safe) | UI |
| D-4 | Confirm step exists but light | Important | Emotional | Heavier commitment language; still no countdown | UI |
| R-1 | Results lack evidence reinterpretation | Important | See X-7 | Declarative rationales | schema, content |
| R-2 | “Put the phone down” is good exit | — | Positive | Keep | — |

### Persistence / chrome

| ID | Finding | Sev | Type | Correction | Affects |
|---|---|---|---|---|---|
| C-1 | Cases chip over status area can collide with Dynamic Island | Moderate | Usability | Reposition; ensure 44pt without covering icons | UI |
| C-2 | Persistence banner copy is player-facing | — | Positive | Keep | — |

---

## Intentional fiction (not defects)

| Choice | Why it stays |
|---|---|
| iOS-lookalike home, bubbles, status bar | DR-8 accepted product risk |
| Real Instagram / Snapchat / Google Maps names | DR-12 |
| Links and Decide as “apps” | Diegetic game verbs; improve entrance, don’t remove |
| Empty filler apps | Believable phone; improve empty states, not fill with content |
| No percentage on results | Design rule |
| Damage as aesthetic | Central cost thesis |

---

## Baseline capture status

| Device | Status |
|---|---|
| iPhone 17e (compact) | via `scripts/capture-design-baseline.sh` |
| iPhone 17 Pro | DesignBaselineCaptureUITests |
| iPhone 17 Pro Max | same |

Artifacts: `design-review/baseline/<device>/*.png` + `MANIFEST.md`.  
Harness **fails** if expected accessibility identifiers are missing (no blank wrong-screen shots).

---

## Priority order for redesign

1. **Critical/Important usability:** navigation hit targets, home noise, Links discoverability, library hierarchy  
2. **Emotional climax:** Decide pacing + Results reinterpretation (schema if needed)  
3. **Accessibility:** Dynamic Type mapping, photo labels, unlock announcements  
4. **Visual system:** icon redraw, app icon, materials consistency  

Do not restyle card stacks without addressing hierarchy and discovery.
