import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/pipelines/gen/gen_context.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/gen/worker_config.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/gen/workflows/clean_queue.dart';

class RunCleanStage implements Stage<GenCleanContext> {
  RunCleanStage(this._workerConfig, this._workflow);

  final WorkerConfig _workerConfig;
  final CleanQueueWorkflow _workflow;

  @override
  String get name => 'run-clean';

  @override
  Future<GenCleanContext> run(GenCleanContext context) async {
    if (context.modules.isEmpty) {
      context.exitCode = 0;
      return context;
    }
    context
      ..workerCount = _workerConfig.resolve(
        context.workerOption,
        context.modules.length,
      )
      ..exitCode = await _workflow.execute(
        workerCount: context.workerCount,
        modules: context.modules,
      );
    return context;
  }
}
