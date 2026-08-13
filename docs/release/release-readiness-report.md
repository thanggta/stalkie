# CARVE — Release readiness report

**Branch:** `release-readiness`  
**Base:** `main` @ `c4a085ab56b96cf2aa2ab677fcb0d4ac04eba089`  
**Report date:** 2026-08-13  
**Effort type:** validation and launch preparation (not a feature phase; not Phase 8)

## Recommendation

### **NOT READY** for App Review  
### **NOT READY** for TestFlight until owner completes signing + ASC product setup

Repository-side preflight, local StoreKit coverage, automated accessibility labels, and playtest *handoff materials* are prepared. The three gates required for “ready for App Review” are **not** all complete:

| Gate | Status |
|---|---|
| Real sandbox StoreKit (not `.storekit`) | **Blocked** — no App Store Connect product / sandbox tester / signing identity on this machine |
| Manual accessibility pass (VoiceOver + Dynamic Type + Reduce Motion on both themes) | **Incomplete** — code audit + automated labels PASS; full manual VO matrix not executed by a human on device/sim |
| External first-player playtest | **Incomplete** — script + observation sheet ready; no external tester; no installable release-equivalent build without signing |

Immediate path: owner completes App Store Connect + signing → TestFlight internal → manual a11y + external playtest → re-score this report.

---

## Exact commit and CI

| Item | Value |
|---|---|
| Starting `main` | `c4a085ab56b96cf2aa2ab677fcb0d4ac04eba089` |
| Phase 7 green head | `6a227ac` |
| Prior green CI | https://github.com/thanggta/stalkie/actions/runs/31657829066 |
| This branch | `release-readiness` |
| Branch head (after this effort) | `c826956` (docs) on top of `6eb9870` (config/a11y) |
| CI for this branch | *(fill after push — must be green before merge)* |

---

## Live Apple guidelines re-read

**Retrieved:** 2026-08-13 (UTC)  
**Source:** https://developer.apple.com/app-store/review/guidelines/  
**Page “Last Updated”:** June 8, 2026 (https://developer.apple.com/news/?id=a233fmpw)

| Guideline | Live text (summary of re-read) | Matches `docs/compliance.md`? |
|---|---|---|
| **5.2.5** Apple Products (ASR & NR) | “Don’t create an app that appears confusingly similar to an existing Apple product, interface (e.g. Finder), app (such as the App Store, iTunes Store, or **Messages**) or advertising theme.” Apple emoji prohibition retained. | **Yes** — core quote unchanged. DR-8 still places the shell inside this rule. |
| **4.1(b)** Copycats (ASR & NR) | “Submitting apps which impersonate other apps or services… may result in removal from the Apple Developer Program.” | **Yes** |
| **4.1(c)** | Cannot use another developer’s icon, brand, or product name in app icon or name without approval. | **Yes** |
| **4.3(b)** Spam | “Don’t submit apps that are indistinguishable from what’s already widely available…” removal if not updated/improved/do not attract customers. | **Yes** |
| **3.1.2** Subscriptions | Apps may offer auto-renewable subscriptions; scam/bait-and-switch language retained. | **Yes** — we still avoid the surface (one-time IAP only). |

Do not treat older in-repo quotations as current without re-checking this URL before each submission.

---

## Workstream 1 — compliance §8 matrix

| # | Checklist item | Result | Evidence |
|---|---|---|---|
| 1 | Re-read 5.2.5 (then 4.1, 4.3, 3.1.2) from live page | **PASS** | Retrieved 2026-08-13 from developer.apple.com; text matches compliance quotes (see above). |
| 2 | No *Apple-authored asset* ships (icons, logos, wordmarks, glyph artwork). N/A “no Apple-like UI” under DR-8. | **PASS** (repo) | App icons are original 180×180 masters under `Sources/CarveUI/Resources/AppIcons/`; marketing `AppIcon.png` 1024×1024 original; no third-party PNGs. `AppIconAssetTests` green. |
| 3 | Theme layer intact (retreat path) | **PASS** | Two themes (`ios_lookalike`, fallback); `ThemeLiteralLintTests` enforces no hardcoded radii/fonts/colors in views. |
| 4 | 4.3(b) differentiation visible early + in screenshots | **MANUAL** | Product loop (discovery gates + forced verdict) is in binary. Screenshots / App Store preview video **not authored**. First-ten-minutes differentiation not proven with an uncontaminated player. |
| 5 | INV-6 asset review every case | **PASS** (repo) | Cases use fictional people; media is authored sources; no third-party brand asset files. Platform brands only as labels via `PhoneAppLabels`. |
| 6 | Real platform brands in screenshots (DR-12) — accept rejection risk; no extra brands; no third-party asset files | **MANUAL** / **PASS** (code) | Brands centralized in `PhoneAppLabels` (`GameSession.swift`). Screenshots not yet produced. |
| 7 | Brand strings single config — revert is config edit | **PASS** | `PhoneAppLabels` only; grep found no Instagram/Snapchat/Google Maps strings outside that config + view type names. |
| 8 | Free first case complete without payment | **PASS** | `five_minutes` access=free; FullLoop UI + unit path; launches with StoreKit failed (`CaseLaunchAccessTests.freeCaseLaunchesWhenStoreKitHasFailed`). |
| 9 | IAP one-time only; no cycle purchases | **PASS** | Catalog paid non-consumable only; no cycle IAP surface. |
| 10 | Catalog only source of product IDs | **PASS** | `cases/catalog.json` → `games.carve.case.dont_wait_up`; `ReleaseConfigLintTests.productIdsLiveOnlyInCatalogNotInUISources`; UI reads `entry.productId`. |
| 11 | Purchase screen: one-time, case name, StoreKit price, not subscription, Restore | **PASS** | `CasePurchaseView` copy + identifiers; local StoreKit UI tests green on Phase 7 CI. |
| 12 | No fake urgency / countdown / preselected / disguised buy | **PASS** | Purchase view is plain; no timers. |
| 13 | Local `.storekit` ≠ proof ASC product exists | **PASS** (process) | Documented in `docs/storekit.md` and this report; ASC status = not configured from this environment. |
| 14 | Case 1 launches with StoreKit unavailable | **PASS** | Free path ignores entitlement load state. |
| 15 | Accessibility baseline | **MANUAL** (partial) | Automated labels + image non-spoiler tests PASS. Full manual matrix incomplete (see Workstream 3). |
| 16 | Age rating matches content | **MANUAL** | ASC form not filled. Content: infidelity, deception — honest 12+/17 territory; owner must rate. |
| 17 | No unused device-data permissions | **PASS** | Info.plist has no usage-description keys; lint test enforces. |
| 18 | Privacy nutrition label matches collection | **MANUAL** | No analytics SDK in binary (repo). Owner must declare **no data collected** (or match reality) in ASC. |

### Preflight configuration audit (extra)

| Item | Value / finding | Result |
|---|---|---|
| Bundle ID | `games.carve.app` | Set |
| Marketing version | `0.1.0` | Set (pre-1.0) |
| Build | `1` | Set |
| Deployment target | iOS 17.0 | Set |
| Device family | iPhone only (`TARGETED_DEVICE_FAMILY = 1`) | **PASS** |
| Platforms | `iphoneos iphonesimulator` | **PASS** |
| Mac Catalyst | `SUPPORTS_MACCATALYST = NO` | **PASS** |
| Mac Designed for iPhone | `SUPPORTS_MAC_DESIGNED_FOR_IPHONE = NO` | **PASS** (added this effort) |
| visionOS Designed for iPhone | `SUPPORTS_XR_DESIGNED_FOR_IPHONE = NO` | **PASS** (added this effort) |
| App icon 1024 | Present, non-placeholder | **PASS** |
| Export compliance key | `ITSAppUsesNonExemptEncryption = false` | **PASS** (added this effort) |
| Release signing | `CODE_SIGNING_ALLOWED = NO`, no `DEVELOPMENT_TEAM`, **0** local codesign identities | **FAIL** for device/TestFlight/archive — intentional for CI; **owner action** |
| DEBUG entitlement bypass | `#if DEBUG` only; release filter test in CI | **PASS** |
| Developer reset / case picker | DEBUG-only in `AppBootstrap` | **PASS** |
| Free case if store down | Unit-tested | **PASS** |
| Theme retreat | Two themes + lint | **PASS** |
| Brand centralization | `PhoneAppLabels` | **PASS** |
| Third-party artwork | None found | **PASS** |
| CarveCore purity | `import Foundation` only | **PASS** |

---

## Workstream 2 — App Store Connect + real sandbox

### Configuration status

| Step | Status |
|---|---|
| Non-consumable product `games.carve.case.dont_wait_up` | **Not verified** — no ASC access from this agent/machine |
| Attached to app record `games.carve.app` | **Not verified** |
| Localization “Don’t Wait Up” | **Not verified** |
| Price configured | **Not verified** |
| Agreements / tax / banking clear | **Not verified** |
| Sandbox tester created | **Not verified** |
| Real sandbox purchase/restore matrix (11 steps) | **Not run** |

**Local evidence only (not sandbox):** Phase 7 `StoreKitPurchaseUITests` + `Carve.storekit` + fake entitlement unit tests cover purchase, cancel, restore, unverified rejection, free case with failed store. That is **not** App Store sandbox proof.

### External blocker (exact)

1. No Apple Developer signing identity on the build machine (`security find-identity -v -p codesigning` → 0 identities).  
2. Project ships with `CODE_SIGNING_ALLOWED = NO` (CI-safe). TestFlight/device archive requires owner team + Automatic/Manual signing.  
3. App Store Connect product and sandbox tester cannot be created without owner credentials.  
4. Therefore: **do not claim sandbox verification.**

Owner checklist: `docs/release/asc-owner-checklist.md`.

---

## Workstream 3 — accessibility

### Automated (PASS)

- Identifiers/labels on library cards, purchase buy/restore/close, maps pins, social rows, link nodes, verdict options, results header  
- Authored `accessibilityDescription` on damaged images; tests forbid leaking `depicts`  
- Reduce Motion gates unlock-banner slide  
- Practical 44pt min on primary controls  
- Verdict option VoiceOver label now uses same title-case as on-screen text (`PlayerFacingCopy.verdictOptionLabel`)

### Manual matrix

| Surface | VO order/labels | Dynamic Type (default / AX3 / largest) | Reduce Motion | 44pt | Color-only | Themes | Result |
|---|---|---|---|---|---|---|---|
| Case library | code labels present | **not executed** | n/a | code | progress not color-only | **not executed both** | **MANUAL incomplete** |
| Free-case launch | code | **not executed** | — | — | — | — | **MANUAL incomplete** |
| Purchase / restore | code | **not executed** | — | code 44pt | status not color-only | — | **MANUAL incomplete** |
| Messages / social | code | **not executed** | — | — | — | — | **MANUAL incomplete** |
| Maps pins | label = place name | **not executed** | — | — | — | — | **MANUAL incomplete** |
| Links board | entity display name | **not executed** | — | code | — | — | **MANUAL incomplete** |
| Decide / verdict | options + selected trait | **not executed** | — | code | selected has trait | — | **MANUAL incomplete** |
| Results | header trait | **not executed** | — | — | wrong uses text not only color | — | **MANUAL incomplete** |
| Save-failure retry | identifiers present | **not executed** | — | — | — | — | **MANUAL incomplete** |

**Environment attempted:** iOS Simulator available (iPhone 17 Pro Max / CARVE-SK-TEST, iOS 26.5). Full VoiceOver + Dynamic Type pass requires interactive human control; not substituted with “labels exist in code.”

### Defects

| ID | Severity | Finding | Status |
|---|---|---|---|
| A11Y-1 | Important | Theme fonts use fixed `Font.system(size:)` — Dynamic Type scaling is limited (already noted in `docs/accessibility.md`) | **Open** — product follow-up; do not “fix” with truncation |
| A11Y-2 | Minor (fixed) | Verdict option accessibility label used snake_case spaces; visual used Title Case | **Fixed** this branch + unit test |
| A11Y-3 | Important | Full manual VO reading-order pass not executed | **Open** — owner / tester |

Observation sheet: `docs/release/accessibility-observation-sheet.md`.

---

## Workstream 4 — external first-player playtest

| Item | Status |
|---|---|
| Neutral spoiler-free script | **Ready** — `docs/release/playtest-script.md` |
| Observation sheet | **Ready** — `docs/release/playtest-observation-sheet.md` |
| Recruitment handoff | **Ready** — same docs |
| Release-equivalent installable build | **Blocked** on signing / TestFlight |
| External tester | **None available** |
| Playtest completed | **No** |

### Actual playtimes (do not inflate)

| Case | Source | Duration |
|---|---|---|
| `five_minutes` | Internal author-contaminated (`cases/five_minutes/PLAYTEST.md`) | **19 minutes** |
| `dont_wait_up` | Internal author-contaminated (`cases/dont_wait_up/PLAYTEST.md`) | **32 minutes** |
| Design target | Design spec | 45–90 minutes |
| External first-player | — | **Not measured** |

Both internal sessions are honestly **below** target. Content expansion vs target revision is a **later product decision** — not done in this effort.

---

## Final verification (this branch)

Recorded **2026-08-13** on the release-readiness machine (Xcode 26.6 / iOS Simulator 26.5):

| Command | Result |
|---|---|
| `swift test` | **PASS** — 187 tests / 34 suites |
| CarveCLI every case (`five_minutes`, `dont_wait_up`) | **PASS** |
| `swift run CarveCLI --catalog cases/catalog.json` | **PASS** (`OK catalog`) |
| `swift test -c release --filter EntitlementBypassReleaseTests` | **PASS** |
| `swift build --target CarveUI` | **PASS** |
| Release sim build (`xcodebuild -configuration Release`, `CODE_SIGNING_ALLOWED=NO`) | **PASS** |
| FullLoop UI (`FullLoopUITests` on iPhone 17 Pro, iOS 26.5) | **PASS** (~169s) |
| StoreKit UI (`StoreKitPurchaseUITests` on local iOS 26.5) | **FAIL (infra)** — `SKInternalErrorDomain Code=3` / Octane never syncs on 26.5 under xcodebuild (same class of issue CI avoids by preferring 26.0–26.2). **Not a product regression claim.** Prior green: Phase 7 CI run `31657829066`. |
| GitHub Actions after push | *(fill after push)* |

Local StoreKit UI failure on 26.5 is **not** treated as real App Store sandbox evidence either way.

---

## Remaining owner actions (ordered)

1. **Apple Developer Program** — ensure membership active; create/choose team.  
2. **Signing** — set `DEVELOPMENT_TEAM`, enable automatic signing for App Store distribution (keep CI `CODE_SIGNING_ALLOWED=NO` path or use secrets).  
3. **App Store Connect app record** for `games.carve.app` if missing.  
4. **IAP** — complete `docs/release/asc-owner-checklist.md` (product, price, localization, agreements).  
5. **Sandbox tester** — create; run 11-step matrix on device; paste results into this report (no credentials).  
6. **Privacy nutrition label** + **age rating** in ASC.  
7. **Export compliance** — confirm `ITSAppUsesNonExemptEncryption=false` matches reality (no custom crypto).  
8. **Screenshots / preview** showing discovery + Decide (4.3(b) visibility).  
9. **TestFlight** internal build → run `docs/release/accessibility-observation-sheet.md`.  
10. **External first-player** using `docs/release/playtest-script.md` — record real times.  
11. Re-open this report; only then consider **READY FOR TESTFLIGHT** (after 1–5 + installable build) or **READY FOR REVIEW** (after 1–10 + green CI).

---

## What this effort deliberately did not do

- No game redesign, no new apps, no case expansion, no monetization model change  
- No weakening of UI tests, no StoreKit bypass in Release  
- No claim of App Review readiness without the three gates above  
- No padding of cases to hit 45–90 minutes  
- No relitigation of DR-8 / DR-12
