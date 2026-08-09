// tool/validate_case.dart
import 'dart:convert';
import 'dart:io';

import 'package:carve_core/carve_core.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: dart run tool/validate_case.dart <case-directory>');
    exit(1);
  }
  final dir = Directory(args.first);
  if (!dir.existsSync()) {
    stderr.writeln('No such case directory: ${args.first}');
    exit(1);
  }

  final manifestFile = File('${dir.path}/case.json');
  if (!manifestFile.existsSync()) {
    stderr.writeln('Missing case.json in ${args.first}');
    exit(1);
  }

  try {
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;

    final fragments = <String, Map<String, dynamic>>{};
    final fragDir = Directory('${dir.path}/fragments');
    if (fragDir.existsSync()) {
      for (final f in fragDir.listSync()) {
        if (f is! File || !f.path.endsWith('.json')) continue;
        final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        fragments[json['id'] as String] = json;
      }
    }

    final caseFile = parseCase(manifest, fragments);
    final problems = validateCase(caseFile);

    if (problems.isEmpty) {
      stdout.writeln('OK  ${caseFile.id} — "${caseFile.title}"');
      final qs = caseFile.questions.length;
      stdout.writeln('    ${caseFile.fragments.length} fragments, '
          'budget ${caseFile.cycleBudget}, '
          'total cost ${caseFile.totalCarveCost}, '
          '$qs question${qs == 1 ? '' : 's'}');
      exit(0);
    }

    stderr.writeln('FAILED  ${args.first} — ${problems.length} problem(s):');
    for (final p in problems) {
      stderr.writeln('  • $p');
    }
    exit(1);
  } on CaseFormatException catch (e) {
    stderr.writeln('FAILED  ${args.first}');
    stderr.writeln('  • ${e.message}');
    exit(1);
  }
}
