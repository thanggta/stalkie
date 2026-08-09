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
