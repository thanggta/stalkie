// test/loader/case_parser_test.dart
import 'package:carve_core/carve_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> minimalManifest() => {
      'schemaVersion': 1,
      'id': 'test',
      'title': 'Test Case',
      'cycleBudget': 10,
      'sectorMap': [
        {'fragmentId': 'note_001', 'typeHint': 'note', 'integrity': 0.9, 'carveCost': 4}
      ],
      'verdict': {
        'questions': [
          {
            'id': 'q1',
            'prompt': 'Who?',
            'answerType': 'entity',
            'options': ['a', 'b'],
            'correct': 'a',
            'supportedBy': ['note_001']
          }
        ]
      }
    };

Map<String, Map<String, dynamic>> minimalFragments() => {
      'note_001': {
        'id': 'note_001',
        'type': 'note',
        'label': 'A note',
        'damage': {'profile': 'block-loss', 'intensity': 0.2, 'seed': 7},
        'content': {'title': 'x', 'body': 'y', 'modifiedAt': '2026-03-12T02:11:00+07:00'}
      }
    };

void main() {
  test('parses a well-formed case', () {
    final c = parseCase(minimalManifest(), minimalFragments());
    expect(c.id, equals('test'));
    expect(c.fragments['note_001']!.damage.seed, equals(7));
  });

  test('rejects an unknown schemaVersion instead of guessing', () {
    final m = minimalManifest()..['schemaVersion'] = 2;
    expect(() => parseCase(m, minimalFragments()),
        throwsA(isA<CaseFormatException>()));
  });

  test('rejects audio fragments in v1 with a clear error, never silently skipping', () {
    // DR-6: audio is specified but not built. Silent skipping would produce
    // an unsolvable case with no error.
    final frags = minimalFragments();
    frags['audio_001'] = {
      'id': 'audio_001',
      'type': 'audio',
      'label': 'Voicemail',
      'damage': {'profile': 'overwrite', 'intensity': 0.5, 'seed': 3},
      'content': {'source': 'media/vm.m4a', 'durationSec': 34}
    };
    expect(
        () => parseCase(minimalManifest(), frags),
        throwsA(predicate((e) =>
            e is CaseFormatException && e.toString().contains('DR-6'))));
  });

  test('rejects a fragment missing damage.seed', () {
    final frags = minimalFragments();
    (frags['note_001']!['damage'] as Map).remove('seed');
    expect(() => parseCase(minimalManifest(), frags),
        throwsA(isA<CaseFormatException>()));
  });

  test('rejects an unknown damage profile', () {
    final frags = minimalFragments();
    (frags['note_001']!['damage'] as Map)['profile'] = 'sparkles';
    expect(() => parseCase(minimalManifest(), frags),
        throwsA(isA<CaseFormatException>()));
  });
}
