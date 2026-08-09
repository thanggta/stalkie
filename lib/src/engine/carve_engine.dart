// lib/src/engine/carve_engine.dart
import '../models/case_file.dart';
import '../models/fragment.dart';
import '../rules/predicate.dart';

enum CarveOutcome { ok, alreadyCarved, insufficientCycles, unknownFragment }

class CarveResult {
  final CarveOutcome outcome;
  final Fragment? fragment;
  const CarveResult(this.outcome, [this.fragment]);
}

/// Pure game rules. No Flutter, no IO. See CLAUDE.md rule 3.
class CarveEngine {
  final CaseFile caseFile;
  final Set<String> _carved = {};
  final Set<String> _links = {};
  final Set<String> _answered = {};
  int _spent = 0;

  CarveEngine(this.caseFile);

  int get cyclesRemaining => caseFile.cycleBudget - _spent;
  Set<String> get carvedIds => Set.unmodifiable(_carved);

  GameState get state => GameState(
        carvedFragmentIds: Set.unmodifiable(_carved),
        linkedPairs: Set.unmodifiable(_links),
        answeredQuestionIds: Set.unmodifiable(_answered),
      );

  bool canCarve(String fragmentId) {
    final sector = caseFile.sectorFor(fragmentId);
    if (sector == null || _carved.contains(fragmentId)) return false;
    return sector.carveCost <= cyclesRemaining;
  }

  CarveResult carve(String fragmentId) {
    final sector = caseFile.sectorFor(fragmentId);
    if (sector == null) return const CarveResult(CarveOutcome.unknownFragment);
    if (_carved.contains(fragmentId)) {
      return CarveResult(
          CarveOutcome.alreadyCarved, caseFile.fragments[fragmentId]);
    }
    if (sector.carveCost > cyclesRemaining) {
      return const CarveResult(CarveOutcome.insufficientCycles);
    }
    _spent += sector.carveCost;
    _carved.add(fragmentId);
    return CarveResult(CarveOutcome.ok, caseFile.fragments[fragmentId]);
  }

  void link(String a, String b) => _links.add(GameState.linkKey(a, b));

  void markAnswered(String questionId) => _answered.add(questionId);
}
