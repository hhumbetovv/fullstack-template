import 'package:args/command_runner.dart';

import 'package:scripts/src/common/options.dart';
import 'package:scripts/src/core/errors.dart';
import 'package:scripts/src/feature/module_graph/runner.dart';

class ModuleGraphCommand extends Command<int> {
  ModuleGraphCommand() {
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
  String get name => 'module-graph';

  @override
  String get description => 'Generate the workspace dependency graph markdown.';

  @override
  Future<int> run() async {
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
}
