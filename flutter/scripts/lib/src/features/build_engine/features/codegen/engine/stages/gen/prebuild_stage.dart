import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/build_engine/features/codegen/domain/models/smart_build_options.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/pipelines/gen/gen_context.dart';

class PrebuildStage implements Stage<GenWatchContext> {
  PrebuildStage(this._smartBuildRunner);

  final SmartBuildRunner _smartBuildRunner;

  @override
  String get name => 'pre-build';

  @override
  Future<GenWatchContext> run(GenWatchContext context) async {
    if (!context.preBuild || context.modules.isEmpty) {
      return context;
    }
    final exitCode = await _smartBuildRunner(
      const SmartBuildOptions(
        verbose: false,
        dryRun: false,
        maxParallelBuilds: 4,
      ),
    );
    if (exitCode != 0) {
      Console.error(
        'smart-build failed (exit code $exitCode). Continuing watchers.',
      );
    }
    return context;
  }
}
