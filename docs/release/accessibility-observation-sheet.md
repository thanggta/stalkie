# Accessibility — manual observation sheet

Automated labels in CI are **not** a substitute for this pass.  
Checklist origin: `docs/accessibility.md`.

## Session metadata

| Field | Value |
|---|---|
| Date | |
| Device / simulator | |
| OS version | |
| App build / git SHA | |
| Theme A | Phone (`ios_lookalike`) |
| Theme B | Fallback / workstation |
| Text size: default | |
| Text size: AX3 | |
| Text size: largest Accessibility | |
| Reduce Motion | Off / On |
| Tester | |

## Severity guide

- **Critical** — cannot complete a primary task with VO or at large text
- **Important** — can complete with difficulty; missing labels; clipping that hides meaning
- **Minor** — polish, order quirks, redundant announcements

Do **not** “fix” clipping by truncating evidence or verdict questions into unreadability.

---

## Surfaces

For each row: mark Pass / Fail / N/A and note VO speech if wrong.

### 1. Case library

| Check | Default | AX3 | Largest | Theme B | Notes |
|---|---|---|---|---|---|
| Card speaks title, progress, access/price, premise | | | | | |
| Not color alone for lock/progress | | | | | |
| Restore Purchases labeled + hint | | | | | |
| Focus order sensible (header → cards → restore) | | | | | |
| 44pt targets | | | | | |

### 2. Free-case launch (`five_minutes`)

| Check | Result | Notes |
|---|---|---|
| Open card → phone home without trap | | |
| Home app icons labeled with app titles | | |
| Decide hint present | | |

### 3. Paid purchase + restore

| Check | Result | Notes |
|---|---|---|
| “One-time”, case name, StoreKit price, not a subscription | | |
| Buy / Restore / Close labeled | | |
| Cancel copy does not sound like a hard error | | |
| After purchase, return to library / open case without restart | | |

### 4. Messages + social rows

| Check | Result | Notes |
|---|---|---|
| Thread rows speak contact name + preview, not internal ids | | |
| Instagram / Snapchat rows speak display name, not `depicts` | | |
| Image VO uses authored description only | | |

### 5. Maps pins

| Check | Result | Notes |
|---|---|---|
| Pin speaks place label, not color | | |
| Visit list rows labeled | | |

### 6. Links board

| Check | Result | Notes |
|---|---|---|
| Node speaks person display name | | |
| Button trait; 44pt | | |

### 7. Decide + all verdict controls

| Check | Result | Notes |
|---|---|---|
| Option speaks title-case option text | | |
| Selected is a trait, not color only | | |
| Next / File / Review controls labeled | | |
| All 15 questions reachable with VO | | |
| Large text: prompts still readable (no silent truncation of meaning) | | |

### 8. Results

| Check | Result | Notes |
|---|---|---|
| Title is a header | | |
| Wrong answers explain given vs correct in text | | |
| Missed fragments listed in text | | |

### 9. Save-failure warning + retry

| Check | Result | Notes |
|---|---|---|
| Warning announced | | |
| Retry control labeled and activatable | | |

### 10. Reduce Motion

| Check | Result | Notes |
|---|---|---|
| Unlock banner appears without slide animation | | |

---

## Findings log

| ID | Severity | Surface | Repro steps | Expected | Actual | Evidence (screenshot/video) |
|---|---|---|---|---|---|---|
| | | | | | | |

## Sign-off

- [ ] Critical = 0  
- [ ] Important fixed or accepted with owner note  
- [ ] Both themes exercised  
- [ ] Dynamic Type at default, AX3, largest  
- [ ] Reduce Motion on once  

Tester: ________  Date: ________
