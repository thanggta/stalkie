// test/tool/cli_test.dart
import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('exits 0 on the valid sample case', () {
    final r = Process.runSync('dart', ['run', 'tool/validate_case.dart', 'cases/riverside']);
    expect(r.exitCode, equals(0), reason: '${r.stdout}${r.stderr}');
  });

  test('exits 1 and names the directory when the case does not exist', () {
    final r = Process.runSync('dart', ['run', 'tool/validate_case.dart', 'cases/nope']);
    expect(r.exitCode, equals(1));
    expect('${r.stdout}${r.stderr}', contains('cases/nope'));
  });
}
