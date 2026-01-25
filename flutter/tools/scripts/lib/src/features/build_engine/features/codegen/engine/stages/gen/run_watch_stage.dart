import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/pipelines/gen/gen_context.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/gen/workflows/watch_runner.dart';

class RunWatchStage implements Stage<GenWatchContext> {
  RunWatchStage(this._workflow);

  final WatchRunnerWorkflow _workflow;

  @override
  String get name => 'run-watch';

  @override
  Future<GenWatchContext> run(GenWatchContext context) async {
    if (context.modules.isEmpty) {
      context.exitCode = 0;
      return context;
    }
    context.exitCode = await _workflow.execute(context.modules);
    return context;
  }
}
