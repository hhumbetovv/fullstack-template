import 'package:args/command_runner.dart';
import 'package:scripts/src/features/build_engine/features/codegen/commands/build/command.dart';
import 'package:scripts/src/features/build_engine/features/codegen/commands/gen_build/command.dart';
import 'package:scripts/src/features/build_engine/features/codegen/commands/gen_clean/command.dart';
import 'package:scripts/src/features/build_engine/features/codegen/commands/gen_watch/command.dart';
import 'package:scripts/src/features/build_engine/features/codegen/commands/smart_build/command.dart';
import 'package:scripts/src/features/build_engine/features/module_graph/commands/module_graph/command.dart';
import 'package:scripts/src/features/links/commands/build_links_command.dart';
import 'package:scripts/src/features/links/commands/pubspec_links_command.dart';
import 'package:scripts/src/features/links/commands/yaml_links_command.dart';
import 'package:scripts/src/features/locale/commands/command.dart';
import 'package:scripts/src/features/scaffolding/features/create_module/commands/create_module/command.dart';
import 'package:scripts/src/features/scaffolding/features/pub_sync/commands/pub_sync/command.dart';

typedef CommandFactory = Command<int> Function();

CommandRunner<int> createScriptsCommandRunner() {
  final commandFactories = <CommandFactory>[
    CreateModuleCommand.new,
    PubSyncCommand.new,
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

  final runner = CommandRunner<int>(
    'scripts',
    'Automation utilities for the template workspace.',
  );

  for (final factory in commandFactories) {
    runner.addCommand(factory());
  }

  return runner;
}
