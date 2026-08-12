# Accessibility baseline

Checked as part of Phase 7 before monetization ships.

## Automated

- VoiceOver identifiers/labels on case cards, purchase buy/restore/close, library restore,
  Decide/Links icons, map pins, link nodes, verdict options, results title
- Authored `accessibilityDescription` on every original damaged image in both cases
- Tests assert `depicts` is never used as the VoiceOver string
- Reduce Motion skips the unlock-banner slide
- Practical 44pt minimum on purchase, library, replay, verdict options, link nodes, map pins

## Simulator / manual (not CI)

Run VoiceOver on an iPhone simulator and confirm:

1. Case library: each card speaks title, progress, access/price, premise — not color alone
2. Purchase: "one-time", case name, StoreKit price, "not a subscription", Restore Purchases
3. Cancellation copy does not sound like an error
4. Maps pin speaks the place label, not a color
5. Instagram/Snapchat rows speak the counterparty display name, not `depicts`
6. Link node speaks the person's display name
7. Verdict option speaks the option text; selected state is a trait, not color only
8. Results title is a header
9. Dynamic Type at AX sizes: library cards, purchase copy, verdict prompts still readable
10. Reduce Motion: unlock banner appears without the slide

Dynamic Type is not exhaustively snapshotted. Theme fonts go through the system text styles
where the theme layer already does; remaining fixed sizes are a follow-up, not a silent pass.
