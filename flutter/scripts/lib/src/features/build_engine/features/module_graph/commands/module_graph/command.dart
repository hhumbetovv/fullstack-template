import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/di/dependency_setup.dart';
import 'package:scripts/src/features/build_engine/domain/models/module_graph_options.dart';
import 'package:scripts/src/features/build_engine/features/module_graph/commands/module_graph/module_graph_executor.dart';

class ModuleGraphCommand extends ScriptsCommand {
  ModuleGraphCommand()
    : super(
        commandName: 'module-graph',
        commandDescription: 'Generate the workspace dependency graph markdown.',
      ) {
    argParser
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Enable verbose logging output.',
        negatable: false,
      )
      ..addOption(
        'parallel',
        abbr: 'p',
        help: 'Set the max parallel value used in stats.',
        valueHelp: 'count',
        defaultsTo: '4',
      );
  }

  @override
  Future<int> runCommand() async {
    final parallelRaw = argResults?['parallel'] as String? ?? '4';
    final parallel = int.tryParse(parallelRaw);
    if (parallel == null || parallel <= 0) {
      throw const CommandError(
        '`--parallel` must be a positive integer.',
        exitCode: 64,
      );
    }

    final options = ModuleGraphOptions(
      verbose: argResults?['verbose'] as bool? ?? false,
      maxParallelBuilds: parallel,
    );

    configureDependencies();
    return getDependency<ModuleGraphExecutor>().run(options);
  }

  @override
  bool get showStackTrace => argResults?['verbose'] as bool? ?? false;
}
