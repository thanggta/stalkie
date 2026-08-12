# Case Bundle Schema v1

The contract between authors and the engine. **An agent implementing `case_loader` should be
able to work from this document alone.**

Design rule, non-negotiable: **content is declarative data. Never executable script.** This is
invariant INV-5 and a compliance requirement (`docs/compliance.md` §3) — downloadable *content*
is ordinary, downloadable *logic* is where Guideline 3.3.2 bites.

---

## 1. Bundle layout

```
case_five_minutes/
├── case.json           # manifest, sector map, verdict questions, answer key
├── fragments/
│   ├── thread_theo.json
│   ├── thread_sable.json
│   └── record_places.json
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
  "id": "five_minutes",
  "title": "Five Minutes",
  "briefing": "His phone is unlocked on the counter. The shower is still running.",
  "sectorMap": [
    { "fragmentId": "thread_theo", "typeHint": "thread", "integrity": 0.95 },
    { "fragmentId": "calls_recent", "typeHint": "record", "integrity": 0.85 }
  ],
  "verdict": {
    "questions": [
      {
        "id": "q_sable_who",
        "prompt": "Who is Sable to Eli?",
        "answerType": "entity",
        "options": ["coworker", "affair", "party_help", "unknown"],
        "correct": "affair",
        "supportedBy": ["thread_sable", "note_unsent"]
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
| `title` | string | Display name |
| `briefing` | string | Optional author/store copy. Ignored by the engine; shell may show it. |
| `sectorMap[]` | array | Fragments visible at case open (no gate, or gate true on empty state) |
| `sectorMap[].integrity` | float 0–1 | Drives default damage intensity **and** is shown to the player as a hint |
| `verdict.questions[]` | array | Production cases target ~15 concise questions (owner: DR-11). All must be answered to file. |
| `verdict.questions[].correct` | string | The answer key. **Must** appear in `options`. |
| `verdict.questions[].supportedBy` | string[] | Fragment ids that make this answerable. Enforces INV-3 (must be reachable). |

**Removed / do not author:**
- `cycleBudget`, `sectorMap[].carveCost` — gone with DR-11
- `estimatedMinutes` — vestigial from early planning; not loaded, not displayed. Playtime is not a design constant anymore under free browsing.

Extra JSON keys are ignored by the loader, but new cases should not reintroduce the removed fields.

---

## 3. Fragment types

All fragments share an envelope:

```json
{
  "id": "thread_sable",
  "type": "thread",
  "label": "Messages — Sable",
  "damage": { "profile": "block-loss", "intensity": 0.35, "seed": 2201 },
  "hiddenUntil": { "carved": "thread_theo" },
  "revealTiers": [ ... ],
  "content": { ... }
}
```

| Field | Rules |
|---|---|
| `damage.profile` | One of `block-loss`, `scanline-tear`, `partial-decode`, `chroma-bleed`, `overwrite` |
| `damage.intensity` | float 0–1 |
| `damage.seed` | int — **required**. Damage must be deterministic; the same fragment looks the same every session and on every device. |
| `hiddenUntil` | Optional. Declarative unlock gate (§4). Absent + on sector map ⇒ visible at open. |
| `revealTiers[]` | Optional. Progressive reveal on the same fragment. |

`damage.seed` being required is deliberate: random damage would make screenshots
irreproducible and bug reports useless.

### What `damage` means by fragment type (resolved)

The envelope requires `damage` on every fragment so authors and the loader share one shape.
**Rendering does not treat every type the same:**

| Type | What `damage` does |
|---|---|
| `image` | **Applied at runtime** by `CarveDamage` (Metal). Profile + intensity + seed drive the shader. Clean source in `media/` only — never a pre-corrupted asset. |
| `thread`, `note`, `record` | **Not applied as a generator.** Text corruption is **authored inline** with `█` (and `corrupt: true` on thread messages). The engine never invents missing words — which words are lost *is* the puzzle (see §3.1). The `damage` block on text fragments is retained for envelope uniformity and may inform future chrome (e.g. integrity hints); shells must not run Metal profiles on text or invent █ spans from it. |
| `audio` | Not built in v1. |

If a future design needs procedural text damage, that is a decision record — not a silent
shader side-effect.

### 3.1 `thread`

```json
{
  "type": "thread",
  "content": {
    "participants": [
      { "entityId": "eli", "display": "Eli" },
      { "entityId": "sable", "display": "Sable" }
    ],
    "messages": [
      { "at": "2026-08-07T17:49:00+07:00", "from": "eli", "text": "running late. same as last week?", "corrupt": false },
      { "at": "2026-08-07T22:33:00+07:00", "from": "eli", "text": "home. miss you already which is ██████", "corrupt": true }
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
    "depicts": ["sable", "location_river_court"]
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
    "title": "do not send",
    "body": "I keep saying next week and it's been █████",
    "modifiedAt": "2026-08-08T01:17:00+07:00"
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
      ["2026-08-07T17:58:00+07:00", "sable", 94, "out"],
      ["2026-08-10T08:11:00+07:00", null, 0, "missed"]
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

Some fragments are hidden until a condition holds. Rules are **data**, evaluated by a small
fixed interpreter. There is no scripting language and there will not be one.

This is the structure that replaced the cycle budget (DR-11). Free browsing; discovery gates.

```json
{
  "hiddenUntil": {
    "all": [
      { "carved": "thread_theo" },
      { "any": [ { "carved": "calls_recent" }, { "linked": ["eli", "sable"] } ] }
    ]
  }
}
```

### Complete predicate grammar

That is the whole grammar. Adding a predicate requires a decision record.

| Predicate | Shape | True when |
|---|---|---|
| `carved` | `{ "carved": "<fragmentId>" }` | That fragment has been opened |
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
| Every `supportedBy` id resolves and is reachable through unlocks | INV-3 |
| No `hiddenUntil` predicate outside the grammar in §4 | INV-5 |
| No fragment `type` outside the five in §3; `audio` rejected in v1 | DR-6 |
| No unlock cycle (A hidden until B, B hidden until A) | Deadlock |

There is **no** cycle-budget check and **no** solvability solver. INV-1 and INV-2 are gone
(DR-11).

---

## 6. Authoring workflow

1. Author writes `case.json` + fragment files in a text editor (or a spreadsheet → JSON export)
2. `swift run CarveCLI cases/five_minutes` — runs every §5 check
3. Drop clean images in `media/`. No image editing for damage — that's `damage.profile`.
4. Play it in the dev harness
5. Commit

**Success criterion for the whole pipeline (design spec §10.5): a non-engineer completes this
loop without touching Swift.** If authoring case 2 needs code changes, the schema failed.
