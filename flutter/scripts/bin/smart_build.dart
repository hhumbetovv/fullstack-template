import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/command/runner.dart';

Future<void> main(List<String> args) async {
  final runner = createScriptsCommandRunner();
  try {
    final result = await runner.run(['smart-build', ...args]);
    exit(result ?? 0);
  } on UsageException catch (error) {
    stderr
      ..writeln(error)
      ..writeln()
      ..writeln(runner.usage);
    exit(64);
  } on CommandError catch (error) {
    stderr.writeln(error.message);
    exit(error.exitCode);
  }
}
