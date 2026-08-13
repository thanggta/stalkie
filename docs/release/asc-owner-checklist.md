# App Store Connect — owner checklist

**Product ID (must match catalog exactly):** `games.carve.case.dont_wait_up`  
**App bundle ID:** `games.carve.app`  
**Commercial model:** one-time non-consumable case unlock only. No subscription. No cycles.

Local `Apps/Carve/Carve.storekit` and CI UI tests are **not** substitutes for this checklist.

---

## A. Agreements and account

- [ ] Apple Developer Program membership active
- [ ] Paid Applications Agreement accepted
- [ ] Banking complete (no “action required”)
- [ ] Tax forms complete for intended storefronts
- [ ] App record exists for **CARVE** / `games.carve.app` (create if missing)

## B. In-app purchase

- [ ] Create IAP type: **Non-Consumable**
- [ ] Reference name (internal): e.g. Don’t Wait Up
- [ ] Product ID: `games.carve.case.dont_wait_up` — **exact string, no typos**
- [ ] Cleared for Sale: Yes (when ready to test)
- [ ] Price tier chosen (app never hardcodes currency)
- [ ] Localization (at least primary language):
  - Display name: **Don’t Wait Up** (or App Store–length equivalent)
  - Description: one-time unlock of the case; not a subscription
- [ ] Review screenshot / notes if ASC requires them for the IAP
- [ ] Product attached to the **iOS app** version / app record

## C. App metadata (blocking for Review, not for sandbox)

- [ ] Privacy nutrition label matches reality (repo: no analytics SDK; local saves only)
- [ ] Age rating answered honestly (infidelity / relationship deception content)
- [ ] Support URL + marketing URL as required
- [ ] Screenshots show real play: home grid, discovery moment, Decide/verdict — not only title art
- [ ] App Review notes: fiction about fictional people; free case playable without IAP; IAP unlocks second case only; DR-8/DR-12 accepted risks are intentional product choices

## D. Signing / TestFlight

- [ ] Xcode: Development Team set for `Apps/Carve.xcodeproj` target **Carve**
- [ ] Distribution certificate + App Store provisioning profile (or Automatic signing)
- [ ] Archive Release configuration
- [ ] Upload to App Store Connect
- [ ] Internal TestFlight group with at least one device
- [ ] Confirm build installs and free case launches offline-ish (StoreKit may still need network)

## E. Sandbox tester

- [ ] Users and Access → Sandbox → Testers → create tester
- [ ] Use a **new** Apple ID email not previously used on the test device for production IAP
- [ ] On device: Settings → Developer → Sandbox Apple Account (or App Store sign-out pattern for your OS version)
- [ ] **Never** commit tester password, recovery info, or personal data to the repo

## F. Real sandbox matrix (record in release report)

Device: ________  OS: ________  Build: ________  Sandbox alias: ________  Date: ________

| # | Step | Pass? | Notes |
|---|---|---|---|
| 1 | Fresh install, no entitlement | | |
| 2 | `five_minutes` launches free | | |
| 3 | `dont_wait_up` locked | | |
| 4 | Product + localized price from Apple | | |
| 5 | Cancel → stays locked; cancel copy OK | | |
| 6 | Purchase unlocks without restart | | |
| 7 | Relaunch preserves access | | |
| 8 | Delete/reinstall or clean install | | |
| 9 | Restore Purchases unlocks | | |
| 10 | Progress isolated per case | | |
| 11 | Unverified / interrupted path never grants | | |

## G. When done

Update `docs/release/release-readiness-report.md` Workstream 2 from **Not verified** to evidence-backed PASS/FAIL. Do not paste secrets.
