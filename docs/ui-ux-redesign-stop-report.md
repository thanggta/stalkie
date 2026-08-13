# UI/UX redesign — stop report

**Date:** 2026-08-13  
**Branch:** `ui-ux-redesign`  

## Recommendation

### **BLOCKED ON COLD-PLAYER USABILITY TESTING**

The full redesign (Navigation architecture, Links suspicion interaction, Decide pacing, Schema extension, Results UX, Dynamic Type scaling, and Accessibility) is implemented and verified with green test suites (186 unit/integration tests across 34 suites, CarveCLI case & catalog validation, release entitlement bypass, CarveUI build, simulator build, and UI baseline captures).

Per project rules, **interaction validation with a cold non-implementer player is pending** (facilitator handoff script prepared in `docs/ui-ux-usability-notes.md`). Do not claim interaction validation without that live playtest.

After a clean usability pass with a cold player, re-score toward **READY FOR RELEASE-READINESS VALIDATION**.

---

## Deliverables

| Artifact | Path |
|---|---|
| Audit | `docs/ui-ux-audit.md` |
| Direction | `docs/ui-ux-direction.md` |
| Usability notes / handoff | `docs/ui-ux-usability-notes.md` |
| Accessibility report | `docs/accessibility.md` |
| Baseline screenshots | `design-review/baseline/iPhone-17-Pro/` (~30 PNGs) |
| After redesign screenshots | `design-review/after/iPhone-17-Pro/` (~30 PNGs) |
| Design review README | `design-review/README.md` |
| Capture harness | `Apps/CarveUITests/DesignBaselineCaptureUITests.swift` |
| Capture script | `scripts/capture-design-baseline.sh` |

---

## Implemented improvements

1. **Navigation Architecture:** Single coherent navigation model across all app surfaces. Resolved competing back/home controls (removed floating circular back buttons in favor of standard `< Home` / `< Back` leading buttons with explicit 44pt hit targets). Positioned `Cases` chip cleanly at top trailing without overlay collision or coordinate force-tap workarounds.
2. **Links Suspicion Interaction:** Redesigned Links from a debug graph into a diegetic suspicion board. Added dynamic microcopy, avatar initials, distinct node selection styling (scale, thick stroke, checkmark, `.isSelected` trait), dashed suspicion connection lines, connection toast feedback, and VoiceOver announcement notifications. Added automatic stacked list fallback for large Dynamic Type & compact heights.
3. **Decide 15-Question Pacing:** Redesigned Decide from 5-card survey scroll sections to a focused one-dominant-question-at-a-time pacing. Added position indicator ("Question X of 15"), progress bar, draft answer persistence across navigation, precise incomplete guidance, interactive scannable Review screen with direct question editing, and heavy commitment framing on Confirm.
4. **Schema Extension & Results Re-interpretation:** Extended content schema (`docs/content-schema.md`) with optional `rationale` and `evidenceHint` fields on `VerdictQuestion`. Updated parser, validator, `five_minutes`, and `dont_wait_up` case JSON files. Redesigned Results screen (`VerdictResultsView`) to lead with an emotional summary, prioritize wrong calls with "you believed / what was true / why it looked that way", display evidence hints & supporting fragment chips, and separate missed evidence.
5. **Dynamic Type & Accessibility:** Replaced fixed point sizes in `ThemeFonts` with text-style-relative tokens (`Font.system(size:relativeTo:)` / `Font.custom(size:relativeTo:)`). Verified accessibility labels, 44pt hit targets, Reduce Motion, and VoiceOver traits across all screens. Updated `docs/accessibility.md`.
6. **Device Matrix & Layout Safety:** Verified layout budget across compact (iPhone 17e), current Pro (iPhone 17 Pro), and Pro Max (iPhone 17 Pro Max) heights in `SpringBoardLayoutTests`.

---

## Verification

| Check | Result |
|---|---|
| `swift test` | **186** tests / 34 suites PASS |
| CarveCLI `five_minutes` & `dont_wait_up` | PASS |
| CarveCLI `--catalog cases/catalog.json` | PASS |
| Release entitlement bypass test | PASS |
| `swift build --target CarveUI` | PASS |
| Simulator app build (`xcodebuild`) | PASS |
| FullLoop UI test | PASS |
| StoreKit purchase/restore UI tests | PASS |
| Theme-literal lint | PASS |
| Matched before/after captures | PASS (`design-review/after/iPhone-17-Pro/`) |
| GitHub Actions CI | PASS https://github.com/thanggta/stalkie/actions/runs/31664800795 |

---

## Unresolved concerns (honest)

1. Interaction validation with a cold non-implementer player remains **pending live playtest** (facilitator script provided in `docs/ui-ux-usability-notes.md`).
2. Multi-device screenshots (compact / Pro Max) can be generated on demand via `scripts/capture-design-baseline.sh`.

---

## Branch / CI

| | |
|---|---|
| Branch | `ui-ux-redesign` |
| SHA | `3db02591e15cf6d21b5137a89ecc6259ce14ccdb` (and latest commits) |
| CI | https://github.com/thanggta/stalkie/actions/runs/31664800795 |
