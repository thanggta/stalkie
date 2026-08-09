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
