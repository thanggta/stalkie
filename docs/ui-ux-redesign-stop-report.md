# UI/UX redesign — stop report

**Date:** 2026-08-13  
**Branch:** `ui-ux-redesign`  
**Base:** `main` @ `c4a085a`

## Recommendation

### **BLOCKED ON USABILITY TESTING**

The vertical slice is implemented and automated tests are green, but **no non-implementer ran the slice**. Per the phase brief, do not claim interaction validation without that session.

After a clean usability pass on the slice path, re-score toward **READY FOR RELEASE-READINESS VALIDATION** or **NEEDS ANOTHER UX ITERATION**.

---

## Deliverables

| Artifact | Path |
|---|---|
| Audit | `docs/ui-ux-audit.md` |
| Direction | `docs/ui-ux-direction.md` |
| Usability notes / handoff | `docs/ui-ux-usability-notes.md` |
| Baseline screenshots | `design-review/baseline/iPhone-17-Pro/` (~30 PNGs) |
| Capture harness | `Apps/CarveUITests/DesignBaselineCaptureUITests.swift` |
| Capture script | `scripts/capture-design-baseline.sh` |

---

## Implemented improvements (vertical slice)

1. **Case library (game layer)** — CARVE masthead, state chips, stronger CTAs (Open / Continue / Unlock / Review verdict), demoted progress deletion under Manage, Restore secondary.  
2. **Home noise** — two-page SpringBoard; evidence/tools on page 1; filler on page 2; page dots match real page count.  
3. **Navigation hit-testing** — unlock banners only on home; Cases chip trailing overlay (no full-screen hit target); tappable home indicator; larger Back hit targets.  
4. **Links copy** — shorter diegetic prompts; clearer empty state.  
5. **Maps empty** — “No Significant Locations” before gate.  
6. **Decide confirm** — heavier commitment framing (“This is the line.”).  
7. **Photos a11y** — `photos-item-{id}` + labels.  
8. **Empty apps** — Calendar/Mail/etc. believable empties.  
9. **Tests** — Home paging budget tests; FullLoop green; capture harness fails on missing ids.

---

## Deferred (intentionally)

| Item | Why |
|---|---|
| Case-authored home layout schema | Not required yet; two-page generic policy is enough for slice |
| Full icon redraw suite | Asset production; prioritize later |
| App marketing icon redesign | Separate art pass |
| Results authored rationales (schema) | Needs content authoring + validator; structure only for now |
| Full Dynamic Type theme remapping | Important a11y; larger theme change |
| Multi-device capture matrix (17e + Pro Max) | Pro capture complete; script ready for other devices |
| External usability | No tester available |

---

## Accessibility

| Check | Result |
|---|---|
| Automated labels / identifiers | Improved (photos, library hierarchy) |
| Unlock banners no longer cover Back | Fixed (home-only) |
| Manual VoiceOver matrix | Not fully re-run this phase |
| Dynamic Type AX3/largest | Still open (fixed point fonts) |

---

## Device-size

| Device | Result |
|---|---|
| iPhone 17 Pro (sim) | FullLoop + capture suite exercised |
| Compact / Pro Max matrix | Script prepared; not fully re-run after final fixes |
| Layout unit tests | Compact + Pro page budgets |

---

## Verification

| Check | Result |
|---|---|
| `swift test` | **185** tests / 34 suites PASS |
| CarveCLI both cases + catalog | PASS |
| Release entitlement bypass | PASS |
| `swift build --target CarveUI` | PASS |
| FullLoop UI | PASS |
| Design capture (Pro) | PASS (~30 screens) |
| StoreKit UI (local 26.5) | Not re-run (known 26.5 infra issue); CI prefers 26.0–26.2 |
| GitHub Actions | *(fill after push)* |

---

## Unresolved concerns (honest)

1. Usability with a cold player is **unproven**.  
2. Decide still presents five questions per section — pacing improved at confirm, not fully “one question focus.”  
3. Results still lack authored “why wrong was fair” rationales.  
4. Icon craft still uneven.  
5. Capture on compact/Pro Max not re-verified after final nav fixes.  
6. Some UI test paths still use last-resort taps for long verdict lists (scroll, not chrome overlap).

---

## Branch / CI

| | |
|---|---|
| Branch | `ui-ux-redesign` |
| SHA | *(after push)* |
| CI | *(after push)* |
