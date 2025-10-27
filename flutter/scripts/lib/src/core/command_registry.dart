import 'package:args/command_runner.dart';

import 'package:scripts/src/feature/build/command.dart';
import 'package:scripts/src/feature/gen_build/command.dart';
import 'package:scripts/src/feature/gen_clean/command.dart';
import 'package:scripts/src/feature/gen_watch/command.dart';
import 'package:scripts/src/feature/links/build_links_command.dart';
import 'package:scripts/src/feature/links/pubspec_links_command.dart';
import 'package:scripts/src/feature/links/yaml_links_command.dart';
import 'package:scripts/src/feature/locale/command.dart';
import 'package:scripts/src/feature/module_graph/command.dart';
import 'package:scripts/src/feature/smart_build/command.dart';

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
