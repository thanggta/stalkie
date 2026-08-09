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
