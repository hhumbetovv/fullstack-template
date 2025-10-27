import 'package:scripts/src/core/core.dart';

import 'options.dart';
import 'runner.dart';

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

    return generateModuleGraph(options);
  }

  @override
  bool get showStackTrace => argResults?['verbose'] as bool? ?? false;
}
