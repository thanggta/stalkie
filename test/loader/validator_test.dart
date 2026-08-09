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
