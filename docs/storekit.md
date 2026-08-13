# StoreKit local testing and App Store Connect

Local StoreKit configuration is **not** proof that the App Store Connect product exists.

## Commercial model

- `five_minutes` is free and complete
- Additional cases are one-time non-consumable purchases
- No subscription
- Never sell cycles, hints, answers, fragments, or progress
- No backend in v1

## Product ID

The identifier is centralized in `cases/catalog.json`:

```
games.carve.case.dont_wait_up
```

Do not copy this string into views.

## Local testing (no App Store Connect required)

1. Open `Apps/Carve.xcodeproj`
2. The **Carve** scheme already references `Apps/Carve/Carve.storekit`
3. Run the app on a simulator
4. The paid card uses StoreKit Testing. Price comes from StoreKit (`displayPrice`), not JSON
5. UI tests `StoreKitPurchaseUITests` use `SKTestSession` against that file

This exercises purchase, restore, and cancellation locally. It does **not** mean the product
is configured in App Store Connect.

## App Store Connect setup (required before a real sandbox account works)

1. Create an in-app purchase of type **Non-Consumable**
2. Product ID: `games.carve.case.dont_wait_up` (must match the catalog exactly)
3. Localization: display name and description for Don't Wait Up
4. Price tier of your choosing — the app never hardcodes currency
5. Attach the product to the iOS app record
6. Create a sandbox tester to buy it on a device

Until those steps exist, only the local `.storekit` file and protocol fakes are valid tests.

Owner checklist (product, price, sandbox tester, 11-step matrix):
`docs/release/asc-owner-checklist.md`.

## What unit tests cover vs StoreKitTest

| Path | How it is tested |
|---|---|
| Catalog validation, free case with failed store, lock/unlock, unverified, cancel, pending, revoke-preserves-progress, restore, price abstraction, per-case replay | Deterministic fakes in `swift test` |
| Paid purchase and restore on a simulator | `StoreKitPurchaseUITests` + `.storekit` (`SKTestSession`) |
| Real App Store / sandbox account | **Not tested in CI.** Requires App Store Connect. |
