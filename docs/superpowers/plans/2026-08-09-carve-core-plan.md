# CARVE Core Engine — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the pure-Dart core — domain models, case loader, validator, carve engine, and verdict scoring — so a case can be played to a filed verdict headlessly and validated in CI, before any UI exists.

**Architecture:** Pure Dart package with **zero Flutter imports**. The game rules (`carve_engine`, `verdict`) and the content contract (`case_loader`, validator) are the two places where a bug silently corrupts play, so they ship first, fully tested, with no widget harness required. The UI later consumes this package as a dependency.

**Tech Stack:** Dart 3.x, `package:test`, `package:json_annotation` avoided deliberately (hand-written parsing keeps error messages authoring-friendly).

> ### ✅ This plan was executed and verified before publication
>
> Every code block below was built verbatim on **Dart 3.11.5** and run on 2026-08-09:
> `dart analyze` → **No issues found**; `dart test` → **37/37 passed**;
> `dart run tool/validate_case.dart cases/riverside` → exit 0.
>
> The invariants were also confirmed to *fail* when violated — raising `cycleBudget` to 900 on
> the sample case produced `INV-2 violated: total carve cost (34) is within cycleBudget (900)`
> and exit 1. A test that cannot fail when the rule breaks is not evidence, so this was checked
> rather than assumed.
>
> Task step counts ("Expected: PASS (5 tests)") are therefore real, not estimated.

## Global Constraints

- **No Flutter imports anywhere in this plan.** `lib/` must compile under plain `dart test`.
- **Unlock rules use exactly six predicates**: `carved`, `linked`, `answered`, `all`, `any`, `not`. No expression evaluator. (INV-5, `docs/compliance.md` §5)
- **`schemaVersion` must equal `1`**; reject unknown versions rather than guessing.
- **`audio` fragments are rejected in v1** with a clear error, never silently skipped. (DR-6)
- **Validator failures are hard failures.** A malformed case never reaches a player.
- **`damage.seed` is required** on every fragment — damage must be deterministic.
- Every invariant INV-1…INV-5 is enforced by an automated test in this plan. (INV-6 is an asset review, not code.)

**Reference docs:** `docs/superpowers/specs/2026-08-09-carve-design.md`, `docs/content-schema.md`

---

## File Structure

| File | Responsibility |
|---|---|
| `pubspec.yaml` | Package manifest, pure Dart |
| `lib/src/models/fragment.dart` | Fragment domain types + damage spec |
| `lib/src/models/case_file.dart` | Case manifest, sector map, verdict questions |
| `lib/src/rules/predicate.dart` | The six-predicate grammar + evaluator |
| `lib/src/loader/case_parser.dart` | JSON → domain objects, with authoring-friendly errors |
| `lib/src/loader/validator.dart` | All structural + invariant checks |
| `lib/src/loader/solver.dart` | INV-1 solvability search |
| `lib/src/engine/carve_engine.dart` | Cycle budget, carve state, reveal |
| `lib/src/engine/verdict.dart` | Scores filed answers against the answer key |
| `lib/carve_core.dart` | Public exports |
| `tool/validate_case.dart` | CLI entry: `dart run tool/validate_case.dart cases/<id>` |
| `cases/riverside/` | Sample case fixture used by tests |

---

### Task 1: Project scaffold and fragment models

**Files:**
- Create: `pubspec.yaml`, `lib/src/models/fragment.dart`, `lib/carve_core.dart`
- Test: `test/models/fragment_test.dart`

**Interfaces:**
- Produces: `enum FragmentType { thread, image, note, record, audio }`; `class DamageSpec { String profile; double intensity; int seed; }`; `class Fragment { String id; FragmentType type; String label; DamageSpec damage; Map<String, dynamic> content; }`

- [ ] **Step 1: Create the package manifest**

```yaml
# pubspec.yaml
name: carve_core
description: Pure-Dart core engine for CARVE. No Flutter dependencies.
publish_to: none
version: 0.1.0

environment:
  sdk: ^3.5.0

dev_dependencies:
  test: ^1.25.0
  lints: ^4.0.0
```

- [ ] **Step 2: Write the failing test**

```dart
// test/models/fragment_test.dart
import 'package:carve_core/carve_core.dart';
import 'package:test/test.dart';

void main() {
  test('DamageSpec requires a seed so damage renders identically every session', () {
    // Determinism matters: random damage makes screenshots irreproducible
    // and bug reports useless. See docs/content-schema.md section 3.
    final a = DamageSpec(profile: 'block-loss', intensity: 0.4, seed: 8812);
    final b = DamageSpec(profile: 'block-loss', intensity: 0.4, seed: 8812);
    expect(a, equals(b));
  });

  test('fragments with different seeds are not equal', () {
    final a = DamageSpec(profile: 'block-loss', intensity: 0.4, seed: 1);
    final b = DamageSpec(profile: 'block-loss', intensity: 0.4, seed: 2);
    expect(a, isNot(equals(b)));
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `dart test test/models/fragment_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:carve_core/carve_core.dart'`

- [ ] **Step 4: Write minimal implementation**

```dart
// lib/src/models/fragment.dart
enum FragmentType { thread, image, record, note, audio }

class DamageSpec {
  final String profile;
  final double intensity;
  final int seed;

  const DamageSpec({
    required this.profile,
    required this.intensity,
    required this.seed,
  });

  static const allowedProfiles = {
    'block-loss',
    'scanline-tear',
    'partial-decode',
    'chroma-bleed',
    'overwrite',
  };

  @override
  bool operator ==(Object other) =>
      other is DamageSpec &&
      other.profile == profile &&
      other.intensity == intensity &&
      other.seed == seed;

  @override
  int get hashCode => Object.hash(profile, intensity, seed);
}

class Fragment {
  final String id;
  final FragmentType type;
  final String label;
  final DamageSpec damage;
  final Map<String, dynamic> content;

  const Fragment({
    required this.id,
    required this.type,
    required this.label,
    required this.damage,
    required this.content,
  });
}
```

```dart
// lib/carve_core.dart
export 'src/models/fragment.dart';
```

- [ ] **Step 5: Run test to verify it passes**

Run: `dart test test/models/fragment_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 6: Initialise the repository and commit**

The project is not yet a git repo — this is the first commit.

```bash
git init
printf '.dart_tool/\n.packages\npubspec.lock\nbuild/\n' > .gitignore
git add .gitignore pubspec.yaml lib/ test/ docs/ CLAUDE.md README.md
git commit -m "feat: fragment domain models with deterministic damage spec"
```

---

### Task 2: Case manifest models

**Files:**
- Create: `lib/src/models/case_file.dart`
- Modify: `lib/carve_core.dart`
- Test: `test/models/case_file_test.dart`

**Interfaces:**
- Consumes: `Fragment`, `FragmentType` from Task 1
- Produces: `class SectorEntry { String fragmentId; FragmentType typeHint; double integrity; int carveCost; }`; `class VerdictQuestion { String id; String prompt; List<String> options; String correct; List<String> supportedBy; }`; `class CaseFile { int schemaVersion; String id; String title; int cycleBudget; List<SectorEntry> sectorMap; List<VerdictQuestion> questions; Map<String, Fragment> fragments; }`

- [ ] **Step 1: Write the failing test**

```dart
// test/models/case_file_test.dart
import 'package:carve_core/carve_core.dart';
import 'package:test/test.dart';

void main() {
  test('totalCarveCost sums every fragment cost, not just visible ones', () {
    // INV-2 is checked against the total, so this must include hidden fragments.
    final c = CaseFile(
      schemaVersion: 1,
      id: 'test',
      title: 'Test',
      cycleBudget: 10,
      sectorMap: const [
        SectorEntry(fragmentId: 'a', typeHint: FragmentType.note, integrity: 0.9, carveCost: 6),
        SectorEntry(fragmentId: 'b', typeHint: FragmentType.note, integrity: 0.5, carveCost: 9),
      ],
      questions: const [],
      fragments: const {},
    );
    expect(c.totalCarveCost, equals(15));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dart test test/models/case_file_test.dart`
Expected: FAIL — `Undefined class 'CaseFile'`

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/src/models/case_file.dart
import 'fragment.dart';

class SectorEntry {
  final String fragmentId;
  final FragmentType typeHint;
  final double integrity;
  final int carveCost;

  const SectorEntry({
    required this.fragmentId,
    required this.typeHint,
    required this.integrity,
    required this.carveCost,
  });
}

class VerdictQuestion {
  final String id;
  final String prompt;
  final List<String> options;
  final String correct;
  final List<String> supportedBy;

  const VerdictQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correct,
    required this.supportedBy,
  });
}

class CaseFile {
  final int schemaVersion;
  final String id;
  final String title;
  final int cycleBudget;
  final List<SectorEntry> sectorMap;
  final List<VerdictQuestion> questions;
  final Map<String, Fragment> fragments;

  const CaseFile({
    required this.schemaVersion,
    required this.id,
    required this.title,
    required this.cycleBudget,
    required this.sectorMap,
    required this.questions,
    required this.fragments,
  });

  int get totalCarveCost =>
      sectorMap.fold(0, (sum, entry) => sum + entry.carveCost);

  SectorEntry? sectorFor(String fragmentId) {
    for (final e in sectorMap) {
      if (e.fragmentId == fragmentId) return e;
    }
    return null;
  }
}
```

Add to `lib/carve_core.dart`:

```dart
export 'src/models/case_file.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `dart test test/models/case_file_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/ test/
git commit -m "feat: case manifest models"
```

---

### Task 3: The six-predicate grammar

**Files:**
- Create: `lib/src/rules/predicate.dart`
- Modify: `lib/carve_core.dart`
- Test: `test/rules/predicate_test.dart`

**Interfaces:**
- Produces: `abstract class Predicate { bool evaluate(GameState s); }`; `class GameState { Set<String> carvedFragmentIds; Set<String> linkedPairs; Set<String> answeredQuestionIds; }`; `Predicate parsePredicate(Map<String, dynamic> json)` — throws `PredicateFormatException` on anything outside the grammar.

> **Why a fixed grammar:** an expression evaluator is a script interpreter wearing a hat. Six predicates cover every designed gate, validate trivially, and keep us unambiguously on the content side of Guideline 3.3.2. This is INV-5.

- [ ] **Step 1: Write the failing test**

```dart
// test/rules/predicate_test.dart
import 'package:carve_core/carve_core.dart';
import 'package:test/test.dart';

void main() {
  GameState state({Set<String>? carved, Set<String>? linked, Set<String>? answered}) =>
      GameState(
        carvedFragmentIds: carved ?? {},
        linkedPairs: linked ?? {},
        answeredQuestionIds: answered ?? {},
      );

  test('carved predicate is true only after that fragment is recovered', () {
    final p = parsePredicate({'carved': 'thread_001'});
    expect(p.evaluate(state()), isFalse);
    expect(p.evaluate(state(carved: {'thread_001'})), isTrue);
  });

  test('linked predicate is order-independent', () {
    // Players draw connections in either direction; the gate must not care.
    final p = parsePredicate({
      'linked': ['adrian', 'priya']
    });
    expect(p.evaluate(state(linked: {'adrian|priya'})), isTrue);
    expect(p.evaluate(state(linked: {'priya|adrian'})), isTrue);
  });

  test('all requires every child, any requires one', () {
    final all = parsePredicate({
      'all': [
        {'carved': 'a'},
        {'carved': 'b'}
      ]
    });
    expect(all.evaluate(state(carved: {'a'})), isFalse);
    expect(all.evaluate(state(carved: {'a', 'b'})), isTrue);

    final any = parsePredicate({
      'any': [
        {'carved': 'a'},
        {'carved': 'b'}
      ]
    });
    expect(any.evaluate(state(carved: {'a'})), isTrue);
  });

  test('not inverts its child', () {
    final p = parsePredicate({
      'not': {'carved': 'a'}
    });
    expect(p.evaluate(state()), isTrue);
    expect(p.evaluate(state(carved: {'a'})), isFalse);
  });

  test('rejects any predicate outside the six-key grammar', () {
    // INV-5: no expression evaluator, no scripting hook, ever.
    expect(() => parsePredicate({'eval': 'carved("a") && true'}),
        throwsA(isA<PredicateFormatException>()));
    expect(() => parsePredicate({'scriptRef': 'unlock.js'}),
        throwsA(isA<PredicateFormatException>()));
  });

  test('rejects a predicate object with more than one key', () {
    expect(
        () => parsePredicate({'carved': 'a', 'answered': 'q1'}),
        throwsA(isA<PredicateFormatException>()));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dart test test/rules/predicate_test.dart`
Expected: FAIL — `Undefined name 'parsePredicate'`

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/src/rules/predicate.dart
class PredicateFormatException implements Exception {
  final String message;
  PredicateFormatException(this.message);
  @override
  String toString() => 'PredicateFormatException: $message';
}

class GameState {
  final Set<String> carvedFragmentIds;
  /// Canonical form: two entity ids sorted and joined with '|'.
  final Set<String> linkedPairs;
  final Set<String> answeredQuestionIds;

  const GameState({
    required this.carvedFragmentIds,
    required this.linkedPairs,
    required this.answeredQuestionIds,
  });

  static String linkKey(String a, String b) {
    final pair = [a, b]..sort();
    return '${pair[0]}|${pair[1]}';
  }

  bool hasLink(String a, String b) =>
      linkedPairs.contains(linkKey(a, b)) || linkedPairs.contains('$a|$b') ||
      linkedPairs.contains('$b|$a');
}

abstract class Predicate {
  const Predicate();
  bool evaluate(GameState s);
}

class CarvedPredicate extends Predicate {
  final String fragmentId;
  const CarvedPredicate(this.fragmentId);
  @override
  bool evaluate(GameState s) => s.carvedFragmentIds.contains(fragmentId);
}

class LinkedPredicate extends Predicate {
  final String a;
  final String b;
  const LinkedPredicate(this.a, this.b);
  @override
  bool evaluate(GameState s) => s.hasLink(a, b);
}

class AnsweredPredicate extends Predicate {
  final String questionId;
  const AnsweredPredicate(this.questionId);
  @override
  bool evaluate(GameState s) => s.answeredQuestionIds.contains(questionId);
}

class AllPredicate extends Predicate {
  final List<Predicate> children;
  const AllPredicate(this.children);
  @override
  bool evaluate(GameState s) => children.every((c) => c.evaluate(s));
}

class AnyPredicate extends Predicate {
  final List<Predicate> children;
  const AnyPredicate(this.children);
  @override
  bool evaluate(GameState s) => children.any((c) => c.evaluate(s));
}

class NotPredicate extends Predicate {
  final Predicate child;
  const NotPredicate(this.child);
  @override
  bool evaluate(GameState s) => !child.evaluate(s);
}

/// The complete grammar. Adding a key requires a decision record in the design spec.
const _allowedKeys = {'carved', 'linked', 'answered', 'all', 'any', 'not'};

Predicate parsePredicate(Map<String, dynamic> json) {
  if (json.length != 1) {
    throw PredicateFormatException(
        'A predicate must have exactly one key, got ${json.keys.toList()}');
  }
  final key = json.keys.first;
  if (!_allowedKeys.contains(key)) {
    throw PredicateFormatException(
        'Unknown predicate "$key". Allowed: ${_allowedKeys.join(', ')}. '
        'Expression strings and script references are not supported (INV-5).');
  }
  final value = json[key];

  switch (key) {
    case 'carved':
      if (value is! String) {
        throw PredicateFormatException('"carved" needs a fragment id string');
      }
      return CarvedPredicate(value);
    case 'answered':
      if (value is! String) {
        throw PredicateFormatException('"answered" needs a question id string');
      }
      return AnsweredPredicate(value);
    case 'linked':
      if (value is! List || value.length != 2) {
        throw PredicateFormatException('"linked" needs exactly two entity ids');
      }
      return LinkedPredicate(value[0] as String, value[1] as String);
    case 'all':
    case 'any':
      if (value is! List || value.isEmpty) {
        throw PredicateFormatException('"$key" needs a non-empty list');
      }
      final children = value
          .map((c) => parsePredicate(Map<String, dynamic>.from(c as Map)))
          .toList();
      return key == 'all' ? AllPredicate(children) : AnyPredicate(children);
    case 'not':
      if (value is! Map) {
        throw PredicateFormatException('"not" needs a predicate object');
      }
      return NotPredicate(parsePredicate(Map<String, dynamic>.from(value)));
    default:
      throw PredicateFormatException('Unreachable');
  }
}
```

Add to `lib/carve_core.dart`:

```dart
export 'src/rules/predicate.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `dart test test/rules/predicate_test.dart`
Expected: PASS (6 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/ test/
git commit -m "feat: six-predicate unlock grammar with INV-5 enforcement"
```

---

### Task 4: Case parser

**Files:**
- Create: `lib/src/loader/case_parser.dart`
- Modify: `lib/carve_core.dart`
- Test: `test/loader/case_parser_test.dart`

**Interfaces:**
- Consumes: `CaseFile`, `Fragment`, `SectorEntry`, `VerdictQuestion`, `DamageSpec`, `parsePredicate`
- Produces: `CaseFile parseCase(Map<String, dynamic> manifest, Map<String, Map<String, dynamic>> fragmentJsons)`; `class CaseFormatException implements Exception`

- [ ] **Step 1: Write the failing test**

```dart
// test/loader/case_parser_test.dart
import 'package:carve_core/carve_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> minimalManifest() => {
      'schemaVersion': 1,
      'id': 'test',
      'title': 'Test Case',
      'cycleBudget': 10,
      'sectorMap': [
        {'fragmentId': 'note_001', 'typeHint': 'note', 'integrity': 0.9, 'carveCost': 4}
      ],
      'verdict': {
        'questions': [
          {
            'id': 'q1',
            'prompt': 'Who?',
            'answerType': 'entity',
            'options': ['a', 'b'],
            'correct': 'a',
            'supportedBy': ['note_001']
          }
        ]
      }
    };

Map<String, Map<String, dynamic>> minimalFragments() => {
      'note_001': {
        'id': 'note_001',
        'type': 'note',
        'label': 'A note',
        'damage': {'profile': 'block-loss', 'intensity': 0.2, 'seed': 7},
        'content': {'title': 'x', 'body': 'y', 'modifiedAt': '2026-03-12T02:11:00+07:00'}
      }
    };

void main() {
  test('parses a well-formed case', () {
    final c = parseCase(minimalManifest(), minimalFragments());
    expect(c.id, equals('test'));
    expect(c.fragments['note_001']!.damage.seed, equals(7));
  });

  test('rejects an unknown schemaVersion instead of guessing', () {
    final m = minimalManifest()..['schemaVersion'] = 2;
    expect(() => parseCase(m, minimalFragments()),
        throwsA(isA<CaseFormatException>()));
  });

  test('rejects audio fragments in v1 with a clear error, never silently skipping', () {
    // DR-6: audio is specified but not built. Silent skipping would produce
    // an unsolvable case with no error.
    final frags = minimalFragments();
    frags['audio_001'] = {
      'id': 'audio_001',
      'type': 'audio',
      'label': 'Voicemail',
      'damage': {'profile': 'overwrite', 'intensity': 0.5, 'seed': 3},
      'content': {'source': 'media/vm.m4a', 'durationSec': 34}
    };
    expect(
        () => parseCase(minimalManifest(), frags),
        throwsA(predicate((e) =>
            e is CaseFormatException && e.toString().contains('audio'))));
  });

  test('rejects a fragment missing damage.seed', () {
    final frags = minimalFragments();
    (frags['note_001']!['damage'] as Map).remove('seed');
    expect(() => parseCase(minimalManifest(), frags),
        throwsA(isA<CaseFormatException>()));
  });

  test('rejects an unknown damage profile', () {
    final frags = minimalFragments();
    (frags['note_001']!['damage'] as Map)['profile'] = 'sparkles';
    expect(() => parseCase(minimalManifest(), frags),
        throwsA(isA<CaseFormatException>()));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dart test test/loader/case_parser_test.dart`
Expected: FAIL — `Undefined name 'parseCase'`

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/src/loader/case_parser.dart
import '../models/case_file.dart';
import '../models/fragment.dart';

class CaseFormatException implements Exception {
  final String message;
  CaseFormatException(this.message);
  @override
  String toString() => 'CaseFormatException: $message';
}

const _supportedSchemaVersion = 1;
const _v1FragmentTypes = {'thread', 'image', 'record', 'note'};

FragmentType _parseType(String raw, String fragmentId) {
  if (raw == 'audio') {
    throw CaseFormatException(
        'Fragment "$fragmentId" has type "audio", which is not supported in v1 '
        '(see DR-6). Remove it or convert it to a note/record fragment.');
  }
  if (!_v1FragmentTypes.contains(raw)) {
    throw CaseFormatException(
        'Fragment "$fragmentId" has unknown type "$raw". '
        'Allowed: ${_v1FragmentTypes.join(', ')}.');
  }
  return FragmentType.values.firstWhere((t) => t.name == raw);
}

DamageSpec _parseDamage(Map<String, dynamic> json, String fragmentId) {
  final profile = json['profile'];
  final intensity = json['intensity'];
  final seed = json['seed'];

  if (profile is! String || !DamageSpec.allowedProfiles.contains(profile)) {
    throw CaseFormatException(
        'Fragment "$fragmentId" has unknown damage profile "$profile". '
        'Allowed: ${DamageSpec.allowedProfiles.join(', ')}.');
  }
  if (intensity is! num || intensity < 0 || intensity > 1) {
    throw CaseFormatException(
        'Fragment "$fragmentId" damage.intensity must be a number 0..1.');
  }
  if (seed is! int) {
    throw CaseFormatException(
        'Fragment "$fragmentId" is missing damage.seed. Damage must be '
        'deterministic so screenshots and bug reports reproduce.');
  }
  return DamageSpec(
      profile: profile, intensity: intensity.toDouble(), seed: seed);
}

CaseFile parseCase(
  Map<String, dynamic> manifest,
  Map<String, Map<String, dynamic>> fragmentJsons,
) {
  final version = manifest['schemaVersion'];
  if (version != _supportedSchemaVersion) {
    throw CaseFormatException(
        'Unsupported schemaVersion "$version". This build supports '
        '$_supportedSchemaVersion only.');
  }

  final sectorMap = <SectorEntry>[];
  for (final raw in (manifest['sectorMap'] as List)) {
    final e = Map<String, dynamic>.from(raw as Map);
    sectorMap.add(SectorEntry(
      fragmentId: e['fragmentId'] as String,
      typeHint: _parseType(e['typeHint'] as String, e['fragmentId'] as String),
      integrity: (e['integrity'] as num).toDouble(),
      carveCost: e['carveCost'] as int,
    ));
  }

  final questions = <VerdictQuestion>[];
  final verdict = Map<String, dynamic>.from(manifest['verdict'] as Map);
  for (final raw in (verdict['questions'] as List)) {
    final q = Map<String, dynamic>.from(raw as Map);
    questions.add(VerdictQuestion(
      id: q['id'] as String,
      prompt: q['prompt'] as String,
      options: List<String>.from(q['options'] as List),
      correct: q['correct'] as String,
      supportedBy: List<String>.from(q['supportedBy'] as List),
    ));
  }

  final fragments = <String, Fragment>{};
  fragmentJsons.forEach((id, json) {
    fragments[id] = Fragment(
      id: json['id'] as String,
      type: _parseType(json['type'] as String, id),
      label: json['label'] as String,
      damage: _parseDamage(Map<String, dynamic>.from(json['damage'] as Map), id),
      content: Map<String, dynamic>.from(json['content'] as Map),
    );
  });

  return CaseFile(
    schemaVersion: version as int,
    id: manifest['id'] as String,
    title: manifest['title'] as String,
    cycleBudget: manifest['cycleBudget'] as int,
    sectorMap: sectorMap,
    questions: questions,
    fragments: fragments,
  );
}
```

Add to `lib/carve_core.dart`:

```dart
export 'src/loader/case_parser.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `dart test test/loader/case_parser_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/ test/
git commit -m "feat: case parser with authoring-friendly errors"
```

---

### Task 5: Validator — structural and invariant checks

**Files:**
- Create: `lib/src/loader/validator.dart`
- Modify: `lib/carve_core.dart`
- Test: `test/loader/validator_test.dart`

**Interfaces:**
- Consumes: `CaseFile`, `CaseFormatException`
- Produces: `List<String> validateCase(CaseFile c)` — returns human-readable problems, empty list means valid. Does **not** throw; the CLI decides how to present.

> **Scope note — `hiddenUntil` is deferred.** `docs/content-schema.md` §4 defines the unlock
> predicate grammar and §5 lists unlock-cycle detection and reachability-through-gates as
> validator checks. **None of that is built in this plan.** `parseCase` does not read a
> `hiddenUntil` field, `Fragment` has no slot for one, and `validateCase` computes INV-4
> reachability from the sector map alone.
>
> Consequence: **v1 cases must not use `hiddenUntil`.** The grammar and its INV-5 enforcement
> exist and are tested at the `parsePredicate` level (Task 3), ready for Plan 4 (Link board) to
> wire in. Do not improvise gate handling in Task 5 — leaving it out is the intended v1 scope.

- [ ] **Step 1: Write the failing test**

```dart
// test/loader/validator_test.dart
import 'package:carve_core/carve_core.dart';
import 'package:test/test.dart';

CaseFile build({
  int cycleBudget = 10,
  List<SectorEntry>? sectors,
  List<VerdictQuestion>? questions,
  Map<String, Fragment>? fragments,
}) {
  const dmg = DamageSpec(profile: 'block-loss', intensity: 0.2, seed: 1);
  return CaseFile(
    schemaVersion: 1,
    id: 'test',
    title: 'T',
    cycleBudget: cycleBudget,
    sectorMap: sectors ??
        const [
          SectorEntry(fragmentId: 'a', typeHint: FragmentType.note, integrity: 0.9, carveCost: 6),
          SectorEntry(fragmentId: 'b', typeHint: FragmentType.note, integrity: 0.9, carveCost: 9),
        ],
    questions: questions ??
        const [
          VerdictQuestion(id: 'q1', prompt: 'Who?', options: ['x', 'y'], correct: 'x', supportedBy: ['a']),
        ],
    fragments: fragments ??
        {
          'a': const Fragment(id: 'a', type: FragmentType.note, label: 'A', damage: dmg, content: {}),
          'b': const Fragment(id: 'b', type: FragmentType.note, label: 'B', damage: dmg, content: {}),
        },
  );
}

void main() {
  test('a well-formed case produces no problems', () {
    expect(validateCase(build()), isEmpty);
  });

  test('INV-2: rejects a case that can be fully recovered within budget', () {
    // Scarcity is the entire game. A case you can exhaust has no decisions in it.
    final c = build(cycleBudget: 100); // total cost is 15
    expect(validateCase(c), contains(contains('INV-2')));
  });

  test('INV-3: rejects a question whose supportedBy fragment does not exist', () {
    final c = build(questions: const [
      VerdictQuestion(id: 'q1', prompt: 'Who?', options: ['x'], correct: 'x', supportedBy: ['ghost']),
    ]);
    expect(validateCase(c), contains(contains('INV-3')));
  });

  test('INV-4: rejects a fragment that no sector entry references', () {
    const dmg = DamageSpec(profile: 'block-loss', intensity: 0.2, seed: 1);
    final c = build(fragments: {
      'a': const Fragment(id: 'a', type: FragmentType.note, label: 'A', damage: dmg, content: {}),
      'b': const Fragment(id: 'b', type: FragmentType.note, label: 'B', damage: dmg, content: {}),
      'orphan': const Fragment(id: 'orphan', type: FragmentType.note, label: 'O', damage: dmg, content: {}),
    });
    expect(validateCase(c), contains(contains('INV-4')));
  });

  test('rejects a correct answer that is not among the options', () {
    final c = build(questions: const [
      VerdictQuestion(id: 'q1', prompt: 'Who?', options: ['x', 'y'], correct: 'z', supportedBy: ['a']),
    ]);
    expect(validateCase(c), contains(contains('not among its options')));
  });

  test('rejects a sector entry pointing at a missing fragment', () {
    final c = build(sectors: const [
      SectorEntry(fragmentId: 'nope', typeHint: FragmentType.note, integrity: 0.9, carveCost: 20),
    ]);
    expect(validateCase(c), contains(contains('no fragment file')));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dart test test/loader/validator_test.dart`
Expected: FAIL — `Undefined name 'validateCase'`

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/src/loader/validator.dart
import '../models/case_file.dart';

/// Returns a list of human-readable problems. Empty means valid.
/// Never throws — the caller decides how to present failures.
List<String> validateCase(CaseFile c) {
  final problems = <String>[];

  // Every sector entry must resolve to a fragment.
  for (final e in c.sectorMap) {
    if (!c.fragments.containsKey(e.fragmentId)) {
      problems.add(
          'Sector entry "${e.fragmentId}" has no fragment file.');
    }
    if (e.carveCost <= 0) {
      problems.add('Sector entry "${e.fragmentId}" has carveCost <= 0.');
    }
    if (e.integrity < 0 || e.integrity > 1) {
      problems.add('Sector entry "${e.fragmentId}" integrity must be 0..1.');
    }
  }

  // INV-4: no orphan fragments.
  final referenced = c.sectorMap.map((e) => e.fragmentId).toSet();
  for (final id in c.fragments.keys) {
    if (!referenced.contains(id)) {
      problems.add(
          'INV-4 violated: fragment "$id" is unreachable — no sector entry '
          'references it.');
    }
  }

  // INV-2: the case must NOT be fully recoverable within budget.
  if (c.totalCarveCost <= c.cycleBudget) {
    problems.add(
        'INV-2 violated: total carve cost (${c.totalCarveCost}) is within '
        'cycleBudget (${c.cycleBudget}). The player could recover everything, '
        'which removes every decision from the case.');
  }

  // Verdict questions.
  final seenQuestionIds = <String>{};
  for (final q in c.questions) {
    if (!seenQuestionIds.add(q.id)) {
      problems.add('Duplicate verdict question id "${q.id}".');
    }
    if (!q.options.contains(q.correct)) {
      problems.add(
          'Question "${q.id}" has correct answer "${q.correct}" which is '
          'not among its options ${q.options}.');
    }
    if (q.supportedBy.isEmpty) {
      problems.add(
          'INV-3 violated: question "${q.id}" lists no supporting fragments.');
    }
    for (final fid in q.supportedBy) {
      if (!c.fragments.containsKey(fid)) {
        problems.add(
            'INV-3 violated: question "${q.id}" is supported by "$fid", '
            'which does not exist.');
      }
    }
  }

  if (c.questions.isEmpty) {
    problems.add('A case needs at least one verdict question.');
  }

  return problems;
}
```

Add to `lib/carve_core.dart`:

```dart
export 'src/loader/validator.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `dart test test/loader/validator_test.dart`
Expected: PASS (6 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/ test/
git commit -m "feat: case validator enforcing INV-2, INV-3, INV-4"
```

---

### Task 6: Solvability solver (INV-1)

**Files:**
- Create: `lib/src/loader/solver.dart`
- Modify: `lib/src/loader/validator.dart`, `lib/carve_core.dart`
- Test: `test/loader/solver_test.dart`

**Interfaces:**
- Consumes: `CaseFile`
- Produces: `bool isSolvable(CaseFile c)` — true when some subset of fragments within `cycleBudget` supports every verdict question.

> **Why this matters:** INV-1 is the difference between *thinking* a case is winnable and *knowing* it. A case that cannot be solved within budget is unshippable, and a human playtest will not reliably find it. Run this in CI on every case.

**Algorithm:** each question needs at least one of its `supportedBy` fragments carved. That is a minimum-cost hitting-set problem. Case sizes are small (tens of fragments, ≤6 questions), so an exact branch-and-bound over questions is fast and avoids approximation.

- [ ] **Step 1: Write the failing test**

```dart
// test/loader/solver_test.dart
import 'package:carve_core/carve_core.dart';
import 'package:test/test.dart';

const _dmg = DamageSpec(profile: 'block-loss', intensity: 0.2, seed: 1);

CaseFile caseWith({
  required int budget,
  required List<SectorEntry> sectors,
  required List<VerdictQuestion> questions,
}) =>
    CaseFile(
      schemaVersion: 1,
      id: 't',
      title: 'T',
      cycleBudget: budget,
      sectorMap: sectors,
      questions: questions,
      fragments: {
        for (final s in sectors)
          s.fragmentId: Fragment(
              id: s.fragmentId,
              type: FragmentType.note,
              label: s.fragmentId,
              damage: _dmg,
              content: const {}),
      },
    );

void main() {
  test('solvable when the cheapest supporting fragment per question fits budget', () {
    final c = caseWith(
      budget: 10,
      sectors: const [
        SectorEntry(fragmentId: 'a', typeHint: FragmentType.note, integrity: 0.9, carveCost: 4),
        SectorEntry(fragmentId: 'b', typeHint: FragmentType.note, integrity: 0.9, carveCost: 30),
      ],
      questions: const [
        VerdictQuestion(id: 'q1', prompt: '?', options: ['x'], correct: 'x', supportedBy: ['a', 'b']),
      ],
    );
    expect(isSolvable(c), isTrue);
  });

  test('unsolvable when every supporting fragment exceeds budget', () {
    final c = caseWith(
      budget: 5,
      sectors: const [
        SectorEntry(fragmentId: 'a', typeHint: FragmentType.note, integrity: 0.9, carveCost: 40),
        SectorEntry(fragmentId: 'b', typeHint: FragmentType.note, integrity: 0.9, carveCost: 30),
      ],
      questions: const [
        VerdictQuestion(id: 'q1', prompt: '?', options: ['x'], correct: 'x', supportedBy: ['a', 'b']),
      ],
    );
    expect(isSolvable(c), isFalse);
  });

  test('shares a fragment across questions rather than double-paying', () {
    // 'shared' answers both questions; naive per-question summing would
    // charge 12 and wrongly report unsolvable.
    final c = caseWith(
      budget: 7,
      sectors: const [
        SectorEntry(fragmentId: 'shared', typeHint: FragmentType.note, integrity: 0.9, carveCost: 6),
      ],
      questions: const [
        VerdictQuestion(id: 'q1', prompt: '?', options: ['x'], correct: 'x', supportedBy: ['shared']),
        VerdictQuestion(id: 'q2', prompt: '?', options: ['y'], correct: 'y', supportedBy: ['shared']),
      ],
    );
    expect(isSolvable(c), isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dart test test/loader/solver_test.dart`
Expected: FAIL — `Undefined name 'isSolvable'`

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/src/loader/solver.dart
import '../models/case_file.dart';

/// True when some set of fragments costing <= cycleBudget supports every
/// verdict question. Exact branch-and-bound over questions; case sizes are
/// small (tens of fragments, <= 6 questions).
bool isSolvable(CaseFile c) {
  final costOf = <String, int>{
    for (final s in c.sectorMap) s.fragmentId: s.carveCost,
  };

  // Any question with no reachable supporting fragment is unsolvable outright.
  for (final q in c.questions) {
    final reachable = q.supportedBy.where(costOf.containsKey);
    if (reachable.isEmpty) return false;
  }

  var best = 1 << 30;

  void search(int index, Set<String> carved, int spent) {
    if (spent >= best || spent > c.cycleBudget) return;
    if (index == c.questions.length) {
      best = spent;
      return;
    }
    final q = c.questions[index];
    // Already satisfied by a fragment carved for an earlier question.
    if (q.supportedBy.any(carved.contains)) {
      search(index + 1, carved, spent);
      return;
    }
    for (final fid in q.supportedBy) {
      final cost = costOf[fid];
      if (cost == null) continue;
      search(index + 1, {...carved, fid}, spent + cost);
    }
  }

  search(0, <String>{}, 0);
  return best <= c.cycleBudget;
}
```

Wire into the validator — add at the end of `validateCase`, before `return problems;`:

```dart
  if (!isSolvable(c)) {
    problems.add(
        'INV-1 violated: no set of fragments within cycleBudget '
        '(${c.cycleBudget}) supports every verdict question. The case is '
        'unwinnable.');
  }
```

and add the import at the top of `validator.dart`:

```dart
import 'solver.dart';
```

Add to `lib/carve_core.dart`:

```dart
export 'src/loader/solver.dart';
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `dart test`
Expected: PASS — all suites, including the earlier validator tests still green

- [ ] **Step 5: Commit**

```bash
git add lib/ test/
git commit -m "feat: INV-1 solvability solver wired into validator"
```

---

### Task 7: Carve engine

**Files:**
- Create: `lib/src/engine/carve_engine.dart`
- Modify: `lib/carve_core.dart`
- Test: `test/engine/carve_engine_test.dart`

**Interfaces:**
- Consumes: `CaseFile`, `GameState`
- Produces: `class CarveEngine` with `int get cyclesRemaining`, `Set<String> get carvedIds`, `bool canCarve(String fragmentId)`, `CarveResult carve(String fragmentId)`, `void link(String a, String b)`, `GameState get state`; `enum CarveOutcome { ok, alreadyCarved, insufficientCycles, unknownFragment }`; `class CarveResult { CarveOutcome outcome; Fragment? fragment; }`

- [ ] **Step 1: Write the failing test**

```dart
// test/engine/carve_engine_test.dart
import 'package:carve_core/carve_core.dart';
import 'package:test/test.dart';

const _dmg = DamageSpec(profile: 'block-loss', intensity: 0.2, seed: 1);

CaseFile fixture() => CaseFile(
      schemaVersion: 1,
      id: 't',
      title: 'T',
      cycleBudget: 10,
      sectorMap: const [
        SectorEntry(fragmentId: 'a', typeHint: FragmentType.note, integrity: 0.9, carveCost: 4),
        SectorEntry(fragmentId: 'b', typeHint: FragmentType.note, integrity: 0.4, carveCost: 9),
      ],
      questions: const [
        VerdictQuestion(id: 'q1', prompt: '?', options: ['x'], correct: 'x', supportedBy: ['a']),
      ],
      fragments: {
        'a': const Fragment(id: 'a', type: FragmentType.note, label: 'A', damage: _dmg, content: {}),
        'b': const Fragment(id: 'b', type: FragmentType.note, label: 'B', damage: _dmg, content: {}),
      },
    );

void main() {
  test('carving spends cycles and returns the fragment', () {
    final e = CarveEngine(fixture());
    expect(e.cyclesRemaining, equals(10));
    final r = e.carve('a');
    expect(r.outcome, equals(CarveOutcome.ok));
    expect(r.fragment!.id, equals('a'));
    expect(e.cyclesRemaining, equals(6));
  });

  test('carving the same fragment twice does not double-charge', () {
    // Players will re-tap. Charging twice would silently break INV-1's
    // guarantee that the case stays winnable.
    final e = CarveEngine(fixture());
    e.carve('a');
    final second = e.carve('a');
    expect(second.outcome, equals(CarveOutcome.alreadyCarved));
    expect(e.cyclesRemaining, equals(6));
  });

  test('refuses a carve it cannot afford and spends nothing', () {
    final e = CarveEngine(fixture());
    e.carve('b'); // 9 of 10 spent
    final r = e.carve('a'); // needs 4, only 1 left
    expect(r.outcome, equals(CarveOutcome.insufficientCycles));
    expect(e.cyclesRemaining, equals(1));
    expect(e.carvedIds, isNot(contains('a')));
  });

  test('reports unknown fragments rather than throwing', () {
    final e = CarveEngine(fixture());
    expect(e.carve('ghost').outcome, equals(CarveOutcome.unknownFragment));
  });

  test('links are order-independent in the exposed state', () {
    final e = CarveEngine(fixture());
    e.link('priya', 'adrian');
    expect(e.state.hasLink('adrian', 'priya'), isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dart test test/engine/carve_engine_test.dart`
Expected: FAIL — `Undefined name 'CarveEngine'`

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/src/engine/carve_engine.dart
import '../models/case_file.dart';
import '../models/fragment.dart';
import '../rules/predicate.dart';

enum CarveOutcome { ok, alreadyCarved, insufficientCycles, unknownFragment }

class CarveResult {
  final CarveOutcome outcome;
  final Fragment? fragment;
  const CarveResult(this.outcome, [this.fragment]);
}

/// Pure game rules. No Flutter, no IO. See CLAUDE.md rule 3.
class CarveEngine {
  final CaseFile caseFile;
  final Set<String> _carved = {};
  final Set<String> _links = {};
  final Set<String> _answered = {};
  int _spent = 0;

  CarveEngine(this.caseFile);

  int get cyclesRemaining => caseFile.cycleBudget - _spent;
  Set<String> get carvedIds => Set.unmodifiable(_carved);

  GameState get state => GameState(
        carvedFragmentIds: Set.unmodifiable(_carved),
        linkedPairs: Set.unmodifiable(_links),
        answeredQuestionIds: Set.unmodifiable(_answered),
      );

  bool canCarve(String fragmentId) {
    final sector = caseFile.sectorFor(fragmentId);
    if (sector == null || _carved.contains(fragmentId)) return false;
    return sector.carveCost <= cyclesRemaining;
  }

  CarveResult carve(String fragmentId) {
    final sector = caseFile.sectorFor(fragmentId);
    if (sector == null) return const CarveResult(CarveOutcome.unknownFragment);
    if (_carved.contains(fragmentId)) {
      return CarveResult(
          CarveOutcome.alreadyCarved, caseFile.fragments[fragmentId]);
    }
    if (sector.carveCost > cyclesRemaining) {
      return const CarveResult(CarveOutcome.insufficientCycles);
    }
    _spent += sector.carveCost;
    _carved.add(fragmentId);
    return CarveResult(CarveOutcome.ok, caseFile.fragments[fragmentId]);
  }

  void link(String a, String b) => _links.add(GameState.linkKey(a, b));

  void markAnswered(String questionId) => _answered.add(questionId);
}
```

Add to `lib/carve_core.dart`:

```dart
export 'src/engine/carve_engine.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `dart test test/engine/carve_engine_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/ test/
git commit -m "feat: carve engine with cycle budget enforcement"
```

---

### Task 8: Verdict scoring

**Files:**
- Create: `lib/src/engine/verdict.dart`
- Modify: `lib/carve_core.dart`
- Test: `test/engine/verdict_test.dart`

**Interfaces:**
- Consumes: `CaseFile`, `VerdictQuestion`
- Produces: `class VerdictReport { int correct; int total; List<QuestionResult> results; double get accuracy; }`; `class QuestionResult { String questionId; String given; String correct; bool isCorrect; }`; `VerdictReport scoreVerdict(CaseFile c, Map<String, String> answers)`

- [ ] **Step 1: Write the failing test**

```dart
// test/engine/verdict_test.dart
import 'package:carve_core/carve_core.dart';
import 'package:test/test.dart';

CaseFile fixture() => const CaseFile(
      schemaVersion: 1,
      id: 't',
      title: 'T',
      cycleBudget: 10,
      sectorMap: [],
      questions: [
        VerdictQuestion(id: 'q1', prompt: 'Who?', options: ['a', 'b'], correct: 'a', supportedBy: ['f1']),
        VerdictQuestion(id: 'q2', prompt: 'When?', options: ['x', 'y'], correct: 'y', supportedBy: ['f2']),
      ],
      fragments: {},
    );

void main() {
  test('scores on accuracy over answered questions', () {
    final r = scoreVerdict(fixture(), {'q1': 'a', 'q2': 'x'});
    expect(r.correct, equals(1));
    expect(r.total, equals(2));
    expect(r.accuracy, closeTo(0.5, 1e-9));
  });

  test('an unanswered question counts as wrong, not as skipped', () {
    // Filing an incomplete report is a choice with a cost. Silently
    // excluding blanks would let a player score 100% by answering one question.
    final r = scoreVerdict(fixture(), {'q1': 'a'});
    expect(r.correct, equals(1));
    expect(r.total, equals(2));
    expect(r.results.firstWhere((x) => x.questionId == 'q2').isCorrect, isFalse);
  });

  test('ignores answers to questions the case does not ask', () {
    final r = scoreVerdict(fixture(), {'q1': 'a', 'q2': 'y', 'q99': 'z'});
    expect(r.total, equals(2));
    expect(r.correct, equals(2));
  });

  test('a perfect report scores 1.0', () {
    final r = scoreVerdict(fixture(), {'q1': 'a', 'q2': 'y'});
    expect(r.accuracy, equals(1.0));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dart test test/engine/verdict_test.dart`
Expected: FAIL — `Undefined name 'scoreVerdict'`

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/src/engine/verdict.dart
import '../models/case_file.dart';

class QuestionResult {
  final String questionId;
  final String given;
  final String correct;
  final bool isCorrect;

  const QuestionResult({
    required this.questionId,
    required this.given,
    required this.correct,
    required this.isCorrect,
  });
}

class VerdictReport {
  final List<QuestionResult> results;
  const VerdictReport(this.results);

  int get total => results.length;
  int get correct => results.where((r) => r.isCorrect).length;
  double get accuracy => total == 0 ? 0 : correct / total;
}

/// Scores on accuracy, not completeness. An unanswered question is wrong —
/// filing an incomplete report is a choice with a cost.
VerdictReport scoreVerdict(CaseFile c, Map<String, String> answers) {
  final results = <QuestionResult>[];
  for (final q in c.questions) {
    final given = answers[q.id] ?? '';
    results.add(QuestionResult(
      questionId: q.id,
      given: given,
      correct: q.correct,
      isCorrect: given == q.correct,
    ));
  }
  return VerdictReport(results);
}
```

Add to `lib/carve_core.dart`:

```dart
export 'src/engine/verdict.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `dart test test/engine/verdict_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/ test/
git commit -m "feat: verdict scoring on accuracy"
```

---

### Task 9: Sample case fixture and end-to-end playthrough test

**Files:**
- Create: `cases/riverside/case.json`, `cases/riverside/fragments/thread_001.json`, `cases/riverside/fragments/note_002.json`, `cases/riverside/fragments/record_003.json`
- Test: `test/e2e/riverside_test.dart`

**Interfaces:**
- Consumes: everything above

> This is the first case content. Keep it small — it exists to prove the pipeline, and it is the fixture every later refactor is checked against.

- [ ] **Step 1: Write the case manifest**

```json
{
  "schemaVersion": 1,
  "id": "riverside",
  "title": "The Riverside Contract",
  "client": "Nadia Okonjo",
  "briefing": "Drive recovered from a vehicle in the river. Client is the deceased's sister. She wants to know who he met on the 14th.",
  "cycleBudget": 20,
  "estimatedMinutes": 15,
  "sectorMap": [
    { "fragmentId": "thread_001", "typeHint": "thread", "integrity": 0.9, "carveCost": 8 },
    { "fragmentId": "note_002", "typeHint": "note", "integrity": 0.6, "carveCost": 12 },
    { "fragmentId": "record_003", "typeHint": "record", "integrity": 0.4, "carveCost": 14 }
  ],
  "verdict": {
    "questions": [
      {
        "id": "q_who",
        "prompt": "Who did Adrian arrange to meet on the evening of the 14th?",
        "answerType": "entity",
        "options": ["marcus", "nadia", "priya", "unknown"],
        "correct": "priya",
        "supportedBy": ["thread_001", "record_003"]
      }
    ]
  }
}
```

- [ ] **Step 2: Write the fragment files**

```json
// cases/riverside/fragments/thread_001.json
{
  "id": "thread_001",
  "type": "thread",
  "label": "Messages — unknown number",
  "damage": { "profile": "block-loss", "intensity": 0.4, "seed": 8812 },
  "content": {
    "participants": [
      { "entityId": "adrian", "display": "Adrian" },
      { "entityId": "priya", "display": "+84 90 ___ 4471" }
    ],
    "messages": [
      { "at": "2026-03-14T19:04:00+07:00", "from": "priya", "text": "changed my mind. the usual place", "corrupt": false },
      { "at": "2026-03-14T19:06:00+07:00", "from": "adrian", "text": "i can't keep ███████ like this", "corrupt": true }
    ]
  }
}
```

```json
// cases/riverside/fragments/note_002.json
{
  "id": "note_002",
  "type": "note",
  "label": "Note — draft",
  "damage": { "profile": "partial-decode", "intensity": 0.6, "seed": 4413 },
  "content": {
    "title": "draft — do not send",
    "body": "If you're reading this I already ███ to Marcus about the ███████",
    "modifiedAt": "2026-03-12T02:11:00+07:00"
  }
}
```

```json
// cases/riverside/fragments/record_003.json
{
  "id": "record_003",
  "type": "record",
  "label": "Call log — partial",
  "damage": { "profile": "scanline-tear", "intensity": 0.5, "seed": 991 },
  "content": {
    "kind": "call_log",
    "columns": ["at", "entityId", "durationSec", "direction"],
    "rows": [
      ["2026-03-14T18:52:00+07:00", "priya", 47, "in"],
      ["2026-03-14T22:10:00+07:00", null, 0, "missed"]
    ]
  }
}
```

- [ ] **Step 3: Write the failing end-to-end test**

```dart
// test/e2e/riverside_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:carve_core/carve_core.dart';
import 'package:test/test.dart';

CaseFile loadRiverside() {
  final dir = Directory('cases/riverside');
  final manifest = jsonDecode(File('${dir.path}/case.json').readAsStringSync())
      as Map<String, dynamic>;
  final fragments = <String, Map<String, dynamic>>{};
  for (final f in Directory('${dir.path}/fragments').listSync()) {
    if (f is! File || !f.path.endsWith('.json')) continue;
    final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    fragments[json['id'] as String] = json;
  }
  return parseCase(manifest, fragments);
}

void main() {
  test('riverside parses and passes every validator check', () {
    final problems = validateCase(loadRiverside());
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('riverside can be played to a correct verdict within budget', () {
    final c = loadRiverside();
    final engine = CarveEngine(c);

    expect(engine.carve('thread_001').outcome, equals(CarveOutcome.ok));
    engine.link('adrian', 'priya');

    final report = scoreVerdict(c, {'q_who': 'priya'});
    expect(report.accuracy, equals(1.0));
    expect(engine.cyclesRemaining, greaterThanOrEqualTo(0));
  });

  test('riverside cannot be fully recovered — scarcity holds', () {
    final c = loadRiverside();
    expect(c.totalCarveCost, greaterThan(c.cycleBudget));
  });
}
```

- [ ] **Step 4: Run the test**

Run: `dart test test/e2e/riverside_test.dart`
Expected: PASS (3 tests). If `validateCase` reports INV-2, raise a `carveCost` or lower `cycleBudget` until total cost exceeds budget.

- [ ] **Step 5: Commit**

```bash
git add cases/ test/
git commit -m "feat: riverside sample case with end-to-end playthrough test"
```

---

### Task 10: Validator CLI

**Files:**
- Create: `tool/validate_case.dart`
- Test: `test/tool/cli_test.dart`

**Interfaces:**
- Consumes: `parseCase`, `validateCase`
- Produces: CLI `dart run tool/validate_case.dart cases/<id>` — exit 0 valid, exit 1 with problems listed

> This is the command an author runs. It is the whole reason the schema can be edited by a non-engineer (design spec §10.5).

- [ ] **Step 1: Write the failing test**

```dart
// test/tool/cli_test.dart
import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('exits 0 on the valid sample case', () {
    final r = Process.runSync('dart', ['run', 'tool/validate_case.dart', 'cases/riverside']);
    expect(r.exitCode, equals(0), reason: '${r.stdout}${r.stderr}');
  });

  test('exits 1 and names the directory when the case does not exist', () {
    final r = Process.runSync('dart', ['run', 'tool/validate_case.dart', 'cases/nope']);
    expect(r.exitCode, equals(1));
    expect('${r.stdout}${r.stderr}', contains('cases/nope'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dart test test/tool/cli_test.dart`
Expected: FAIL — the tool file does not exist

- [ ] **Step 3: Write minimal implementation**

```dart
// tool/validate_case.dart
import 'dart:convert';
import 'dart:io';

import 'package:carve_core/carve_core.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: dart run tool/validate_case.dart <case-directory>');
    exit(1);
  }
  final dir = Directory(args.first);
  if (!dir.existsSync()) {
    stderr.writeln('No such case directory: ${args.first}');
    exit(1);
  }

  final manifestFile = File('${dir.path}/case.json');
  if (!manifestFile.existsSync()) {
    stderr.writeln('Missing case.json in ${args.first}');
    exit(1);
  }

  try {
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;

    final fragments = <String, Map<String, dynamic>>{};
    final fragDir = Directory('${dir.path}/fragments');
    if (fragDir.existsSync()) {
      for (final f in fragDir.listSync()) {
        if (f is! File || !f.path.endsWith('.json')) continue;
        final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        fragments[json['id'] as String] = json;
      }
    }

    final caseFile = parseCase(manifest, fragments);
    final problems = validateCase(caseFile);

    if (problems.isEmpty) {
      stdout.writeln('OK  ${caseFile.id} — "${caseFile.title}"');
      final qs = caseFile.questions.length;
      stdout.writeln('    ${caseFile.fragments.length} fragments, '
          'budget ${caseFile.cycleBudget}, '
          'total cost ${caseFile.totalCarveCost}, '
          '$qs question${qs == 1 ? '' : 's'}');
      exit(0);
    }

    stderr.writeln('FAILED  ${args.first} — ${problems.length} problem(s):');
    for (final p in problems) {
      stderr.writeln('  • $p');
    }
    exit(1);
  } on CaseFormatException catch (e) {
    stderr.writeln('FAILED  ${args.first}');
    stderr.writeln('  • ${e.message}');
    exit(1);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `dart test test/tool/cli_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 5: Run the whole suite**

Run: `dart test`
Expected: PASS — every suite green

- [ ] **Step 6: Commit**

```bash
git add tool/ test/
git commit -m "feat: validate_case CLI for authors"
```

---

## Definition of done for this plan

- [ ] `dart test` green, every suite
- [ ] `dart run tool/validate_case.dart cases/riverside` exits 0
- [ ] `lib/` contains zero Flutter imports (`grep -r "package:flutter" lib/` returns nothing)
- [ ] INV-1 through INV-5 each have at least one test that fails when the invariant is broken
- [ ] A case can be authored, validated, and played headlessly without touching Dart

---

## Follow-on plans (not in scope here)

Each produces working software on its own. Write them as separate plans when this one lands.

| Plan | Scope | Depends on |
|---|---|---|
| **2 — Damage shaders** | The five profiles as Flutter fragment shaders; golden-image tests for determinism at a fixed seed | This plan |
| **3 — Workstation shell UI** | Sector map, fragment viewers per type, cycle counter. **Compliance gate:** `docs/compliance.md` §1 do/don't table reviewed before merge | Plans 1–2 |
| **4 — Link board** | Entity graph, player-drawn connections, wiring `linked` predicates to real play | Plan 1 |
| **5 — Verdict UI + entitlement** | Filing flow, report screen, one-time IAP case packs. **Never sell cycles.** | Plans 1, 3 |
| **6 — Case 2** | The real test of the pipeline: authored with zero code changes | All |
