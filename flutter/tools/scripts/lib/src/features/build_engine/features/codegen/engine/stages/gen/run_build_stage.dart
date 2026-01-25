import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/pipelines/gen/gen_context.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/gen/workflows/build_runner_workflow.dart';

class RunBuildStage implements Stage<GenBuildContext> {
  RunBuildStage(this._workflow);

  final BuildRunnerWorkflow _workflow;

  @override
  String get name => 'run-build';

  @override
  Future<GenBuildContext> run(GenBuildContext context) async {
    if (context.modules.isEmpty) {
      return context;
    }
    context.exitCode = await _workflow.execute(context.modules);
    return context;
  }
}
