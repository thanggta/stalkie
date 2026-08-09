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
