import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/features/build_engine/domain/models/build_state.dart';
import 'package:scripts/src/features/build_engine/features/codegen/commands/smart_build/run.dart';
import 'package:scripts/src/features/build_engine/features/codegen/domain/models/smart_build_options.dart';

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
        valueHelp: 'count|auto',
        defaultsTo: BuildState.maxParallelBuildsDefault.toString(),
      )
      ..addFlag(
        'optimized',
        help: 'Use the experimental dependency-driven scheduler.',
        negatable: false,
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

    final parallelRaw = argResults?['parallel'] as String?;
    final parsed = _parseParallelOption(parallelRaw);

    final options = SmartBuildOptions(
      verbose: argResults?['verbose'] as bool? ?? false,
      dryRun: argResults?['dry-run'] as bool? ?? false,
      maxParallelBuilds: parsed.value,
      targetModule: rest.isEmpty ? null : rest.first,
      optimized: argResults?['optimized'] as bool? ?? false,
      autoParallel: parsed.isAuto,
    );

    return runSmartBuild(options);
  }

  @override
  bool get showStackTrace => argResults?['verbose'] as bool? ?? false;
}

_ParallelParseResult _parseParallelOption(String? raw) {
  if (raw == null) {
    return _ParallelParseResult(
      value: BuildState.maxParallelBuildsDefault,
      isAuto: false,
    );
  }

  if (raw.toLowerCase() == 'auto') {
    return _ParallelParseResult(
      value: BuildState.computeAutoParallelism(),
      isAuto: true,
    );
  }

  final value = int.tryParse(raw);
  if (value == null || value <= 0) {
    throw const CommandError(
      '`--parallel` must be a positive integer or `auto`.',
      exitCode: 64,
    );
  }

  return _ParallelParseResult(value: value, isAuto: false);
}

class _ParallelParseResult {
  const _ParallelParseResult({
    required this.value,
    required this.isAuto,
  });

  final int value;
  final bool isAuto;
}
