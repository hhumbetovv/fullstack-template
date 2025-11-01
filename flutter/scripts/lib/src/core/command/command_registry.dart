import 'package:args/command_runner.dart';
import 'package:scripts/src/feature/build/command/command.dart';
import 'package:scripts/src/feature/gen/command/build_command.dart';
import 'package:scripts/src/feature/gen/command/clean_command.dart';
import 'package:scripts/src/feature/gen/command/watch_command.dart';
import 'package:scripts/src/feature/links/command/build_links_command.dart';
import 'package:scripts/src/feature/links/command/pubspec_links_command.dart';
import 'package:scripts/src/feature/links/command/yaml_links_command.dart';
import 'package:scripts/src/feature/locale/command/command.dart';
import 'package:scripts/src/feature/module_graph/command/command.dart';
import 'package:scripts/src/feature/smart_build/command/command.dart';

typedef CommandFactory = Command<int> Function();

final List<CommandFactory> _commandFactories = [
  BuildCommand.new,
  GenBuildCommand.new,
  GenCleanCommand.new,
  GenWatchCommand.new,
  SmartBuildCommand.new,
  ModuleGraphCommand.new,
  BuildLinksCommand.new,
  PubspecLinksCommand.new,
  YamlLinksCommand.new,
  LocaleCommand.new,
];

void registerScriptsCommands(CommandRunner<int> runner) {
  for (final factory in _commandFactories) {
    runner.addCommand(factory());
  }
}
