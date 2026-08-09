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
