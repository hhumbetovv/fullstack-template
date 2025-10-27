import 'package:args/command_runner.dart';

import 'package:scripts/src/core/command_registry.dart';

CommandRunner<int> createScriptsCommandRunner() {
  final runner = CommandRunner<int>(
    'scripts',
    'Automation utilities for the template workspace.',
  );

  registerScriptsCommands(runner);
  return runner;
}
