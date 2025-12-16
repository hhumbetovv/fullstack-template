import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/shared/ports/module_graph_port.dart';
import 'package:scripts/src/shared/stages/pipeline_context.dart';

class BuildPlanStage<T extends PipelineContext> implements Stage<T> {
  const BuildPlanStage(this._moduleGraphPort);

  final ModuleGraphPort _moduleGraphPort;

  @override
  String get name => 'build-plan';

  @override
  Future<T> run(T context) async {
    context.buildPlan = _moduleGraphPort.buildPlan(context.state);
    return context;
  }
}
