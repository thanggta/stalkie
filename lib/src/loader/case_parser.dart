// lib/src/loader/case_parser.dart
import '../models/case_file.dart';
import '../models/fragment.dart';

class CaseFormatException implements Exception {
  final String message;
  CaseFormatException(this.message);
  @override
  String toString() => 'CaseFormatException: $message';
}

const _supportedSchemaVersion = 1;
const _v1FragmentTypes = {'thread', 'image', 'record', 'note'};

FragmentType _parseType(String raw, String fragmentId) {
  if (raw == 'audio') {
    throw CaseFormatException(
        'Fragment "$fragmentId" has type "audio", which is not supported in v1 '
        '(see DR-6). Remove it or convert it to a note/record fragment.');
  }
  if (!_v1FragmentTypes.contains(raw)) {
    throw CaseFormatException(
        'Fragment "$fragmentId" has unknown type "$raw". '
        'Allowed: ${_v1FragmentTypes.join(', ')}.');
  }
  return FragmentType.values.firstWhere((t) => t.name == raw);
}

DamageSpec _parseDamage(Map<String, dynamic> json, String fragmentId) {
  final profile = json['profile'];
  final intensity = json['intensity'];
  final seed = json['seed'];

  if (profile is! String || !DamageSpec.allowedProfiles.contains(profile)) {
    throw CaseFormatException(
        'Fragment "$fragmentId" has unknown damage profile "$profile". '
        'Allowed: ${DamageSpec.allowedProfiles.join(', ')}.');
  }
  if (intensity is! num || intensity < 0 || intensity > 1) {
    throw CaseFormatException(
        'Fragment "$fragmentId" damage.intensity must be a number 0..1.');
  }
  if (seed is! int) {
    throw CaseFormatException(
        'Fragment "$fragmentId" is missing damage.seed. Damage must be '
        'deterministic so screenshots and bug reports reproduce.');
  }
  return DamageSpec(
      profile: profile, intensity: intensity.toDouble(), seed: seed);
}

CaseFile parseCase(
  Map<String, dynamic> manifest,
  Map<String, Map<String, dynamic>> fragmentJsons,
) {
  final version = manifest['schemaVersion'];
  if (version != _supportedSchemaVersion) {
    throw CaseFormatException(
        'Unsupported schemaVersion "$version". This build supports '
        '$_supportedSchemaVersion only.');
  }

  final sectorMap = <SectorEntry>[];
  for (final raw in (manifest['sectorMap'] as List)) {
    final e = Map<String, dynamic>.from(raw as Map);
    sectorMap.add(SectorEntry(
      fragmentId: e['fragmentId'] as String,
      typeHint: _parseType(e['typeHint'] as String, e['fragmentId'] as String),
      integrity: (e['integrity'] as num).toDouble(),
      carveCost: e['carveCost'] as int,
    ));
  }

  final questions = <VerdictQuestion>[];
  final verdict = Map<String, dynamic>.from(manifest['verdict'] as Map);
  for (final raw in (verdict['questions'] as List)) {
    final q = Map<String, dynamic>.from(raw as Map);
    questions.add(VerdictQuestion(
      id: q['id'] as String,
      prompt: q['prompt'] as String,
      options: List<String>.from(q['options'] as List),
      correct: q['correct'] as String,
      supportedBy: List<String>.from(q['supportedBy'] as List),
    ));
  }

  final fragments = <String, Fragment>{};
  fragmentJsons.forEach((id, json) {
    fragments[id] = Fragment(
      id: json['id'] as String,
      type: _parseType(json['type'] as String, id),
      label: json['label'] as String,
      damage: _parseDamage(Map<String, dynamic>.from(json['damage'] as Map), id),
      content: Map<String, dynamic>.from(json['content'] as Map),
    );
  });

  return CaseFile(
    schemaVersion: version as int,
    id: manifest['id'] as String,
    title: manifest['title'] as String,
    cycleBudget: manifest['cycleBudget'] as int,
    sectorMap: sectorMap,
    questions: questions,
    fragments: fragments,
  );
}
