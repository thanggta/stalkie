// test/e2e/riverside_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:carve_core/carve_core.dart';
import 'package:test/test.dart';

CaseFile loadRiverside() {
  final dir = Directory('cases/riverside');
  final manifest = jsonDecode(File('${dir.path}/case.json').readAsStringSync())
      as Map<String, dynamic>;
  final fragments = <String, Map<String, dynamic>>{};
  for (final f in Directory('${dir.path}/fragments').listSync()) {
    if (f is! File || !f.path.endsWith('.json')) continue;
    final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    fragments[json['id'] as String] = json;
  }
  return parseCase(manifest, fragments);
}

void main() {
  test('riverside parses and passes every validator check', () {
    final problems = validateCase(loadRiverside());
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('riverside can be played to a correct verdict within budget', () {
    final c = loadRiverside();
    final engine = CarveEngine(c);

    expect(engine.carve('thread_001').outcome, equals(CarveOutcome.ok));
    engine.link('adrian', 'priya');

    final report = scoreVerdict(c, {'q_who': 'priya'});
    expect(report.accuracy, equals(1.0));
    expect(engine.cyclesRemaining, equals(12));
  });

  test('riverside cannot be fully recovered — scarcity holds', () {
    final c = loadRiverside();
    expect(c.totalCarveCost, greaterThan(c.cycleBudget));
  });
}
