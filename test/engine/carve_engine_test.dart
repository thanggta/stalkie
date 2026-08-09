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
