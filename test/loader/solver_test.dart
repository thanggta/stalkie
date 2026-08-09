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
