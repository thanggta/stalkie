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
