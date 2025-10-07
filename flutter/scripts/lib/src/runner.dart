import 'package:args/command_runner.dart';
import 'package:scripts/src/commands/smart_build_command.dart';

CommandRunner<int> createScriptsCommandRunner() {
  final runner = CommandRunner<int>(
    'scripts',
    'Automation utilities for the template workspace.',
  );

  return runner..addCommand(SmartBuildCommand());
}
