import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/build_engine/domain/models/pipeline_context.dart';
import 'package:scripts/src/features/build_engine/module_graph_port.dart';

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
