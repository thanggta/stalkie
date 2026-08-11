# Case Bundle Schema v1

The contract between authors and the engine. **An agent implementing `case_loader` should be
able to work from this document alone.**

Design rule, non-negotiable: **content is declarative data. Never executable script.** This is
invariant INV-5 and a compliance requirement (`docs/compliance.md` §3) — downloadable *content*
is ordinary, downloadable *logic* is where Guideline 3.3.2 bites.

---

## 1. Bundle layout

```
case_riverside/
├── case.json           # manifest, sector map, verdict questions, answer key
├── fragments/
│   ├── thread_001.json
│   ├── image_004.json
│   └── record_002.json
└── media/
    ├── img_004_source.webp   # CLEAN source. Damage applied at runtime.
    └── ...
```

**`media/` holds clean sources only.** Never ship a pre-damaged asset — degradation is a
runtime shader driven by the fragment's `damage` block (design spec §5). This is what keeps
one source image serving many reveal states.

---

## 2. `case.json`

```json
{
  "schemaVersion": 1,
  "id": "riverside",
  "title": "The Riverside Contract",
  "client": "Nadia Okonjo",
  "briefing": "Drive recovered from a vehicle in the river. Client is the deceased's sister. She wants to know who he met on the 14th.",
  "cycleBudget": 120,
  "estimatedMinutes": 60,
  "sectorMap": [
    { "fragmentId": "thread_001", "typeHint": "thread", "integrity": 0.9, "carveCost": 8 },
    { "fragmentId": "image_004", "typeHint": "image", "integrity": 0.3, "carveCost": 22 }
  ],
  "verdict": {
    "questions": [
      {
        "id": "q_who",
        "prompt": "Who did Adrian meet on the evening of the 14th?",
        "answerType": "entity",
        "options": ["marcus", "nadia", "priya", "unknown"],
        "correct": "priya",
        "supportedBy": ["thread_001", "image_004", "record_002"]
      }
    ]
  }
}
```

### Field reference — `case.json`

| Field | Type | Rules |
|---|---|---|
| `schemaVersion` | int | Must be `1`. Loader rejects unknown versions rather than guessing. |
| `id` | string | `^[a-z0-9_]+$`, unique across all cases |
| `cycleBudget` | int | The scarce resource. Must satisfy INV-1 and INV-2. |
| `sectorMap[]` | array | The regions visible at case open |
| `sectorMap[].integrity` | float 0–1 | Drives default damage intensity **and** is shown to the player as a hint |
| `sectorMap[].carveCost` | int | Cycles to recover. Convention: higher for lower integrity. |
| `verdict.questions[]` | array | 3–6 per case |
| `verdict.questions[].correct` | string | The answer key. **Must** appear in `options`. |
| `verdict.questions[].supportedBy` | string[] | Fragment ids that make this answerable. Enforces INV-3. |

---

## 3. Fragment types

All fragments share an envelope:

```json
{
  "id": "thread_001",
  "type": "thread",
  "label": "Messages — unknown number",
  "damage": { "profile": "block-loss", "intensity": 0.4, "seed": 8812 },
  "revealTiers": [ ... ],
  "content": { ... }
}
```

| Field | Rules |
|---|---|
| `damage.profile` | One of `block-loss`, `scanline-tear`, `partial-decode`, `chroma-bleed`, `overwrite` |
| `damage.intensity` | float 0–1 |
| `damage.seed` | int — **required**. Damage must be deterministic; the same fragment looks the same every session and on every device. |
| `revealTiers[]` | Optional. Progressive reveal — spend more cycles on the same fragment for a cleaner result. |

`damage.seed` being required is deliberate: random damage would make screenshots
irreproducible and bug reports useless.

### 3.1 `thread`

```json
{
  "type": "thread",
  "content": {
    "participants": [
      { "entityId": "adrian", "display": "Adrian" },
      { "entityId": "unknown_1", "display": "+84 90 ___ 4471" }
    ],
    "messages": [
      { "at": "2026-03-14T19:04:00+07:00", "from": "unknown_1", "text": "changed my mind. the usual place", "corrupt": false },
      { "at": "2026-03-14T19:06:00+07:00", "from": "adrian", "text": "i can't keep ███████ like this", "corrupt": true }
    ]
  }
}
```

Corruption in text is authored inline with `█` and flagged `corrupt: true`. The engine does not
generate text corruption — an author decides *which words* are lost, because which words are
lost is the puzzle.

### 3.2 `image`

```json
{
  "type": "image",
  "content": {
    "source": "media/img_004_source.webp",
    "capturedAt": "2026-03-14T21:47:00+07:00",
    "exifIntact": true,
    "depicts": ["priya", "location_pier"]
  }
}
```

`depicts` is metadata for the link board and for INV-3 validation. It is **never shown as a
label** — the player identifies people themselves. That's the game.

### 3.3 `note`

```json
{
  "type": "note",
  "content": {
    "title": "draft — do not send",
    "body": "If you're reading this I already ███ to Marcus about the ███████",
    "modifiedAt": "2026-03-12T02:11:00+07:00"
  }
}
```

### 3.4 `record`

```json
{
  "type": "record",
  "content": {
    "kind": "call_log",
    "columns": ["at", "entityId", "durationSec", "direction"],
    "rows": [
      ["2026-03-14T18:52:00+07:00", "unknown_1", 47, "in"],
      ["2026-03-14T22:10:00+07:00", null, 0, "missed"]
    ]
  }
}
```

`kind` ∈ `call_log` | `location` | `transaction`. `null` in a row renders as an unrecovered
cell — the most useful gap type, because the player can see *that* something happened without
knowing what.

### 3.5 `audio` — specified, not built in v1

```json
{
  "type": "audio",
  "content": { "source": "media/vm_002.m4a", "durationSec": 34, "transcript": "partial" }
}
```

The loader must **reject** `audio` fragments in v1 with a clear error rather than silently
skipping them (DR-6).

---

## 4. Unlock rules — declarative only

> **Not implemented in v1.** The grammar below is defined and its INV-5 enforcement is tested,
> but `hiddenUntil` is not parsed, stored, or validated by the core plan — it lands in Plan 4
> (Link board). **v1 cases must not use `hiddenUntil`.** See the scope note under Task 5 of
> `docs/superpowers/plans/2026-08-09-carve-core-plan.md`.

Some fragments are hidden until a condition holds. Rules are **data**, evaluated by a small
fixed interpreter. There is no scripting language and there will not be one.

```json
{
  "hiddenUntil": {
    "all": [
      { "carved": "thread_001" },
      { "any": [ { "carved": "image_004" }, { "linked": ["adrian", "priya"] } ] }
    ]
  }
}
```

### Complete predicate grammar

That is the whole grammar. Adding a predicate requires a decision record.

| Predicate | Shape | True when |
|---|---|---|
| `carved` | `{ "carved": "<fragmentId>" }` | That fragment has been recovered |
| `linked` | `{ "linked": ["<entityA>", "<entityB>"] }` | Player has drawn that connection |
| `answered` | `{ "answered": "<questionId>" }` | That verdict question is filed |
| `all` | `{ "all": [ ...predicates ] }` | Every child is true |
| `any` | `{ "any": [ ...predicates ] }` | At least one child is true |
| `not` | `{ "not": <predicate> }` | Child is false |

**Why a fixed grammar rather than an expression string:** an expression evaluator is a script
interpreter wearing a hat. Six predicates cover every gate we've designed, they're trivially
validated, and they keep us unambiguously on the content side of Guideline 3.3.2.

---

## 5. Validator

`case_loader` runs these at load time. **All are hard failures** — a malformed case must never
reach a player.

| Check | Enforces |
|---|---|
| `schemaVersion` == 1 | Forward-compat |
| Every `sectorMap[].fragmentId` resolves to a file | INV-4 |
| Every fragment file is referenced by the sector map or is reachable via `hiddenUntil` | INV-4 |
| Every `verdict.questions[].correct` ∈ its `options` | Authoring error |
| Every `supportedBy` id resolves and is reachable | INV-3 |
| Σ `carveCost` over all fragments > `cycleBudget` | INV-2 |
| A solver reaches every `correct` answer within `cycleBudget` | INV-1 |
| No `hiddenUntil` predicate outside the grammar in §4 | INV-5 |
| No fragment `type` outside the five in §3; `audio` rejected in v1 | DR-6 |
| No unlock cycle (A hidden until B, B hidden until A) | Deadlock |

The INV-1 solver check is the interesting one: it's a small search over carve orderings that
proves the case is winnable. **Run it in CI on every case.** It is the difference between
"we think it's solvable" and knowing.

---

## 6. Authoring workflow

1. Author writes `case.json` + fragment files in a text editor (or a spreadsheet → JSON export)
2. `swift run CarveCLI cases/riverside` — runs every §5 check
3. Drop clean images in `media/`. No image editing for damage — that's `damage.profile`.
4. Play it in the dev harness
5. Commit

**Success criterion for the whole pipeline (design spec §10.5): a non-engineer completes this
loop without touching Swift.** If authoring case 2 needs code changes, the schema failed.
