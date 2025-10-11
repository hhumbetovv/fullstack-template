import 'package:args/command_runner.dart';
import 'package:scripts/src/commands/build_command.dart';
import 'package:scripts/src/commands/build_links_command.dart';
import 'package:scripts/src/commands/gen_build_command.dart';
import 'package:scripts/src/commands/gen_clean_command.dart';
import 'package:scripts/src/commands/gen_watch_command.dart';
import 'package:scripts/src/commands/locale_command.dart';
import 'package:scripts/src/commands/module_graph_command.dart';
import 'package:scripts/src/commands/pubspec_links_command.dart';
import 'package:scripts/src/commands/smart_build_command.dart';
import 'package:scripts/src/commands/yaml_links_command.dart';

CommandRunner<int> createScriptsCommandRunner() {
  final runner = CommandRunner<int>(
    'scripts',
    'Automation utilities for the template workspace.',
  );

  return runner
    ..addCommand(BuildCommand())
    ..addCommand(GenBuildCommand())
    ..addCommand(GenCleanCommand())
    ..addCommand(GenWatchCommand())
    ..addCommand(SmartBuildCommand())
    ..addCommand(ModuleGraphCommand())
    ..addCommand(BuildLinksCommand())
    ..addCommand(PubspecLinksCommand())
    ..addCommand(YamlLinksCommand())
    ..addCommand(LocaleCommand());
}
