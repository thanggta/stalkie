# Accessibility report & baseline

**Verified:** 2026-08-13  
**Target:** iOS Simulator (iPhone 17 Pro / iPhone 17e / iPhone 17 Pro Max), Xcode 26, iOS 26.5 runtime.

## Dynamic Type & typography scaling

- Replaced fixed point sizes in `ThemeFonts` with text-style-relative tokens (`Font.system(size:relativeTo:)` / `Font.custom(size:relativeTo:)`).
- Both themes (`iosLookalike` and `fallbackWorkstation`) scale cleanly across default, AX3, and AX5 text sizes.
- Screen layouts (Library cards, Decide question cards, Links suspicion board, Results wrong cards, Purchase screen) reflow cleanly:
  - CTA buttons stack vertically at AX sizes when text expands.
  - Links switches automatically to an accessible list view at AX text sizes so nodes and long labels never overlap.
  - Verdict prompts and option cards use flexible multi-line wrapping and `.fixedSize(horizontal: false, vertical: true)` to prevent prompt truncation.

## VoiceOver matrix

- **Case library:** Each card announces title, progress state ("Free", "In progress", "Filed"), premise, and CTA. Restore and Manage actions have distinct labels.
- **Phone shell / Home:** App icons announce app title and unread badge status.
- **Messages / Threads:** Monogram avatar and thread row speak counterparty display name and message preview without revealing spoiler IDs (`depicts` metadata is never spoken).
- **Photos:** Every image grid cell carries an explicit `photos-item-{id}` identifier and authored `accessibilityDescription`.
- **Links app:** Node buttons speak person name with `.isButton` and `.isSelected` traits when active. Connection actions trigger system `AccessibilityNotification.Announcement`.
- **Maps app:** Location pins speak location name and unlock status.
- **Decide flow:** Questions announce position ("Question X of 15"), section titles are headers (`.isHeader`), and option cards state `.isSelected` trait when chosen.
- **Results screen:** Emotional headline acts as header; wrong cards announce "You believed", "What was true", rationale, and supporting evidence.
- **Purchase screen:** Product title, price, legal disclosures ("One-time purchase · Not a subscription"), and Restore action have clear hit targets and VoiceOver ordering.

## Motion & contrast

- **Reduce Motion:** Respected globally. Skips SpringBoard unlock banner slide animation in favor of simple fade transition.
- **Color independence:** Status, unread badges, selection states, and verdict correct/wrong indicators use text/traits/icons in addition to color.
- **Hit targets:** 44pt minimum touch targets enforced across all primary interactive controls and top bar navigation actions.

## Unresolved findings

- None. All views pass automated tests, Dynamic Type relative scaling, and VoiceOver identifier audits.
