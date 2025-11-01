import 'package:args/command_runner.dart';
import 'package:scripts/src/cli/build/command.dart';
import 'package:scripts/src/cli/gen/build_command.dart';
import 'package:scripts/src/cli/gen/clean_command.dart';
import 'package:scripts/src/cli/gen/watch_command.dart';
import 'package:scripts/src/cli/links/build_links_command.dart';
import 'package:scripts/src/cli/links/pubspec_links_command.dart';
import 'package:scripts/src/cli/links/yaml_links_command.dart';
import 'package:scripts/src/cli/locale/command.dart';
import 'package:scripts/src/cli/module_graph/command.dart';
import 'package:scripts/src/cli/smart_build/command.dart';

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
