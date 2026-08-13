# CARVE — UI/UX Design Direction

**Date:** 2026-08-13  
**Status:** Approved for vertical-slice implementation on `ui-ux-redesign`  
**Inputs:** `docs/ui-ux-audit.md`, design spec, compliance (DR-8/DR-12), accessibility baseline, internal playtests.

This document is the contract before broad implementation. Changes that contradict it need a short amendment here first.

---

## 1. Experience principles

1. **His phone, not your dashboard.** Inside a case, chrome, apps, and empty states must feel like a private device left unlocked.
2. **The game layer is honest.** Library, purchase, restore, and progress management never pretend to be apps on his phone.
3. **Noticing is progress.** When the phone opens further, the player should feel *I found something* — not *I completed a quest step*.
4. **Suspicion is constructed.** Links is assembling a belief, not editing a graph.
5. **Filing is a line you cross.** Decide and Results carry emotional weight equal to the best written thread.
6. **Clarity without tutorial walls.** Prefer diegetic feedback and progressive disclosure over instructions.
7. **Platform conventions serve the fiction.** 44pt targets, VO order, Dynamic Type, and predictable back/home — without sanding off the drama.

---

## 2. Game layer vs fictional phone layer

| | Game layer | Phone layer |
|---|---|---|
| Surfaces | Case library, purchase, load failure | Home, apps, Links, Decide, Results (in-phone) |
| Visual | Darker/quieter stage; large case art; product type | iOS-lookalike (DR-8 theme) |
| Voice | Second person about *her choice* | First-person device UI |
| Escape | Always obvious return | “Cases” chip returns to library without looking like Settings |

Theme data must still drive both. Prefer a `Theme.role` or dedicated game-layer palette tokens rather than hardcoded colors in views.

---

## 3. Visual hierarchy

1. **Primary:** What changes belief (threads, damaged images, Links nodes, verdict questions).  
2. **Secondary:** Navigation, progress, badges.  
3. **Tertiary:** Decorative phone chrome (weather widget, filler apps, status glyphs).

Never give tertiary equal optical weight to primary.

---

## 4. Typography scale

Keep tokens in `ThemeFonts`. Direction:

| Role | Token | Behavior |
|---|---|---|
| Game masthead | largeTitle | Library only |
| Screen title | title / largeTitle (phone apps) | Messages-style large titles where appropriate |
| Body evidence | body / bubble | Readable; scales with Dynamic Type |
| Meta | caption / footnote | Timestamps, access chips |
| Verdict prompt | headline | One clear question |

**Dynamic Type:** Resolve fonts with system text styles + relative sizing (`Font.system(.body)` equivalents bridged through theme), not bare fixed sizes only. At AX sizes, stack CTAs vertically; do not truncate verdict prompts.

---

## 5. Spacing and layout rhythm

Use `ThemeSpacing` exclusively (xxs→xxl).

- Library cards: `md` internal, `lg` between cards.  
- Phone lists: Messages row padding is the reference.  
- Compact phones: home must keep dock + ≥1 icon row + home indicator (`SpringBoardLayout` already budgets this).  
- Critical apps (Messages, Notes, Phone, Photos, and unlocked Links/Decide/Maps) must never be truncated off the only page without a second page.

---

## 6. Surface elevation / material

| Surface | Treatment |
|---|---|
| Library background | Solid dark/game grouped, not pure iOS white |
| Case card | Elevated continuous corner; artwork hero |
| Phone home wallpaper | Full-bleed image/gradient |
| Dock | Ultra-thin material (keep) |
| Unlock banner | Material + dark wash; compact lock-screen language |
| Verdict | Grouped background; elevated question cards |
| Destructive (file / delete) | Destructive color only on the action that crosses the line |

---

## 7. Icon construction rules

- Original drawing only — never Apple/Meta/Snap/Google asset files.  
- Shared grid: 180×180 masters, consistent corner continuous radius, similar optical mass.  
- Platform apps: recognizable silhouette language; CARVE apps (Links, Decide) slightly more “tool-like” but still phone-icon grammar.  
- Filler apps: lower detail OK if weight matches.  
- Marketing app icon: unlocked phone / private life tension — not a generic abstract mark.

---

## 8. Color and contrast

- Follow theme palettes; both `ios_lookalike` and `fallbackWorkstation` must remain valid.  
- Status/progress never color-only (pair with text/traits).  
- Destructive red reserved for file / delete / wrong-call emphasis.  
- Accent for selection and primary CTAs on game layer.

---

## 9. Motion and haptics

- Reduce Motion: opacity only for unlock banner and icon press (existing).  
- Default: short spring for banner; light scale on icon press.  
- Optional light impact on successful Links connection and on File (not on every answer).  
- No countdown, fake progress, or manipulative urgency.

---

## 10. Navigation model

```
Library ──open──► Phone home ◄── home / dock language
                      │
                      ├── App (list) ──► Fragment detail ── back ──► App
                      ├── Links
                      ├── Decide ──► sections ──► review ──► confirm ──► Results
                      └── Cases chip ──► Library
```

Rules:

- One clear back target per screen.  
- Home returns to SpringBoard, not library.  
- Cases chip is the only game-layer escape from the phone.  
- Overlays (status, banner, Cases) must not intercept app chrome taps except their own controls.  
- UI tests must not need coordinate force-taps after this work lands.

---

## 11. Unlock / discovery feedback hierarchy

| Priority | Channel | Use for |
|---|---|---|
| 1 | Banner (tap → app) | New *app* or high-stakes content (e.g. Maps after link) |
| 2 | Home attention | Links / Decide first appearance (pulse badge or soft highlight once) |
| 3 | App icon badge | Unread count in that app |
| 4 | Row “NEW” | Unread fragment in list |

Dismissed banner does not delete badge. Banner never during Decide filing (already true).

---

## 12. Empty and loading states

- Calendar / Mail / Safari: short believable empties (“No Events”, “No Mail”).  
- Maps before gate: “No Significant Locations” (or equivalent), not a broken map.  
- Library loading: existing launch loading.  
- Purchase price loading: keep “Loading price…”.

---

## 13. Error and retry

- Persistence banner: keep player copy + Try again.  
- Purchase fail: calm, no blame.  
- Case load failure: not a white void — title + body + path back to library.

---

## 14. Case library states

| State | Chip | Primary CTA |
|---|---|---|
| Free, not started | Free | Open |
| Free/Owned, in progress | In progress | Continue |
| Free/Owned, filed | Filed | Review verdict |
| Paid, locked | Price or Locked | Unlock |
| Paid, owned | Owned | Open / Continue / Review |
| Unavailable | Unavailable | Disabled + explanation |
| Coming soon | Coming soon | Disabled |

Restore Purchases: secondary text button.  
Delete all progress: nested under Manage, destructive confirmation.  
Replay: secondary on card when progress ≠ not started.

---

## 15. Purchase states

Keep: one-time, case name, StoreKit price, not a subscription, Restore, Close.  
Add: case artwork, clearer hierarchy.  
Never fake urgency.

---

## 16. Links interaction

1. Empty: “People show up as you read the phone.”  
2. Tap node A → selected.  
3. Tap node B → link; clear selection; show connection in list.  
4. If link unlocks content → banner “Something new on Maps” (example) without spoiling.  
5. VO: selection trait; announce connection; 44pt nodes; reflow on compact (vertical list fallback if canvas would clip).

Not a freeform graph editor. No multi-edge tools.

---

## 17. Decide / verdict pacing

Preserve: 15 questions, all required, accuracy scoring, no %, no timer, leave before file, filed immutable.

Improve:

- Intro: keep accusation framing.  
- Sections: keep three thematic parts; emphasize current question; answered questions collapse or dim.  
- Progress: “Part 2 of 3” + answered count.  
- Incomplete: message next to Next control.  
- Review: readable list of claims.  
- Confirm: quiet full-screen weight — “File this. You don’t get a clean undo.”  
- File button: destructive styling.

---

## 18. Results presentation

Order:

1. Emotional headline (wrong-count language — keep).  
2. Where you were wrong (prompt, you said, truth).  
3. Optional authored rationale per wrong question (schema).  
4. What you saw clearly (compact).  
5. What you never opened (replay bait).  
6. Put the phone down.

No score percentage. No generic “you got 80%” prose from counts.

---

## 19. Accessibility behavior

- Every interactive control: label, traits, 44pt min.  
- Photos items: stable ids + descriptions.  
- Unlock: accessibility notification when content appears.  
- Selected verdict option: `.isSelected`.  
- VO order follows narrative: title → content → primary action.  
- Reduce Motion honored.  
- Both themes.

---

## 20. Compact phone and Dynamic Type

- Compact: dock always visible; critical apps on page 1; filler to page 2 if needed.  
- AX3+: library CTA full width; verdict options full width; Links list mode.  
- Never hide File / Open / Buy because of truncation.

---

## Annotated wireframes (lightweight)

### Case library

```
┌─────────────────────────────┐
│ CARVE                       │  game masthead
│ His phones. One at a time.  │
│                             │
│ ┌─────────────────────────┐ │
│ │     [ case artwork ]    │ │
│ │ Five Minutes            │ │
│ │ premise…                │ │
│ │ Free · Not started      │ │
│ │ [ Open                ] │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ Don't Wait Up           │ │
│ │ Locked · $x.xx          │ │
│ │ [ Unlock              ] │ │
│ └─────────────────────────┘ │
│                             │
│ Restore purchases           │  secondary
│ Manage…                     │  delete nested
└─────────────────────────────┘
```

### Home (after Links unlocks)

```
┌─────────────────────────────┐
│ status                      │
│ ┌─ unlock banner ─────────┐ │  priority 1 if new
│ │ Maps · New location     │ │
│ └─────────────────────────┘ │
│ [ weather widget        ]   │  tertiary
│ Ft Cal Ph Cam               │
│ Mail Notes ★Links Decide    │  Links/Decide attention once
│ Maps IG Snap …              │
│        ● ○                  │  dots match real pages
│ ( Phone Msg Photos Safari ) │  dock
│          ──                 │
└─────────────────────────────┘
```

### Links

```
┌─────────────────────────────┐
│ ← Home          Links       │
│ Tap a name, then who they   │
│ connect to.                 │
│                             │
│      (Eli)────(Sable)       │  clear edge
│                             │
│ Connections                 │
│ Eli — Sable                 │
└─────────────────────────────┘
```

### Decide intro → confirm

```
Intro                         Confirm
┌──────────────┐             ┌──────────────┐
│ You are about│             │ File this.   │
│ to accuse…   │             │              │
│              │             │ 15 answers   │
│ [ I am ready]│             │ locked in.   │
└──────────────┘             │ [ File ]     │  destructive
                             └──────────────┘
```

### Results

```
┌─────────────────────────────┐
│ What you decided            │
│ 3 of your calls were wrong. │
│                             │
│ Where you were wrong        │
│ ┌─────────────────────────┐ │
│ │ prompt                  │ │
│ │ You said X · It was Y   │ │
│ │ (authored rationale)    │ │
│ └─────────────────────────┘ │
│ What you never opened       │
│ [ Put the phone down ]      │
└─────────────────────────────┘
```

### Purchase

```
┌─────────────────────────────┐
│ Close                       │
│ [ art ]  Don't Wait Up      │
│ premise                     │
│ One-time · Not subscription │
│ $x.xx                       │
│ [ Buy Don't Wait Up · $ ]   │
│ Restore Purchases           │
└─────────────────────────────┘
```

---

## Vertical slice (implementation order)

Ship first as one coherent path:

**Library → five_minutes → discover Sable → Links → Maps → Decide → Results**

1. Library hierarchy + demoted destructive actions  
2. Home noise reduction + Links/Decide entrance + real page dots  
3. Navigation hit-test fix (chrome)  
4. Links board clarity + unlock feedback on connection  
5. Decide pacing + heavier confirm  
6. Results structure (rationales deferred if schema not ready — structure only)  
7. Photos a11y ids  
8. Tests for the above  

Then extend polish to `dont_wait_up` without caseId branches.

---

## Explicit non-goals this iteration

- Case content expansion for playtime  
- Monetization changes  
- Abandoning DR-8 / DR-12  
- Expression-language unlocks  
- Full icon redraw of all 30 apps in one pass (prioritize thin/broken masters + Links/Decide)
