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
