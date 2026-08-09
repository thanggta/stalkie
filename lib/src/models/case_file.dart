import 'fragment.dart';

class SectorEntry {
  final String fragmentId;
  final FragmentType typeHint;
  final double integrity;
  final int carveCost;

  const SectorEntry({
    required this.fragmentId,
    required this.typeHint,
    required this.integrity,
    required this.carveCost,
  });
}

class VerdictQuestion {
  final String id;
  final String prompt;
  final List<String> options;
  final String correct;
  final List<String> supportedBy;

  const VerdictQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correct,
    required this.supportedBy,
  });
}

class CaseFile {
  final int schemaVersion;
  final String id;
  final String title;
  final int cycleBudget;
  final List<SectorEntry> sectorMap;
  final List<VerdictQuestion> questions;
  final Map<String, Fragment> fragments;

  const CaseFile({
    required this.schemaVersion,
    required this.id,
    required this.title,
    required this.cycleBudget,
    required this.sectorMap,
    required this.questions,
    required this.fragments,
  });

  int get totalCarveCost =>
      sectorMap.fold(0, (sum, entry) => sum + entry.carveCost);

  SectorEntry? sectorFor(String fragmentId) {
    for (final e in sectorMap) {
      if (e.fragmentId == fragmentId) return e;
    }
    return null;
  }
}
