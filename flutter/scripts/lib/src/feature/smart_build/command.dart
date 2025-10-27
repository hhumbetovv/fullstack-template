import 'package:scripts/src/core/core.dart';

import 'options.dart';
import 'runner.dart';

class SmartBuildCommand extends ScriptsCommand {
  SmartBuildCommand()
    : super(
        commandName: 'smart-build',
        commandDescription:
            'Build module graph intelligently using build_runner.',
      ) {
    argParser
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Enable verbose logging output.',
        negatable: false,
      )
      ..addFlag(
        'dry-run',
        help: 'Show the build plan without executing build_runner.',
        negatable: false,
      )
      ..addOption(
        'parallel',
        abbr: 'p',
        help: 'Set the maximum number of modules built in parallel.',
        valueHelp: 'count',
        defaultsTo: '4',
      );
  }

  @override
  Future<int> runCommand() async {
    final rest = argResults?.rest ?? <String>[];
    if (rest.length > 1) {
      throw const CommandError(
        'Only one module name can be provided to smart-build.',
        exitCode: 64,
      );
    }

    final parallelRaw = argResults?['parallel'] as String? ?? '4';
    final parallel = int.tryParse(parallelRaw);
    if (parallel == null || parallel <= 0) {
      throw const CommandError(
        '`--parallel` must be a positive integer.',
        exitCode: 64,
      );
    }

    final options = SmartBuildOptions(
      verbose: argResults?['verbose'] as bool? ?? false,
      dryRun: argResults?['dry-run'] as bool? ?? false,
      maxParallelBuilds: parallel,
      targetModule: rest.isEmpty ? null : rest.first,
    );

    return runSmartBuild(options);
  }

  @override
  bool get showStackTrace => argResults?['verbose'] as bool? ?? false;
}
