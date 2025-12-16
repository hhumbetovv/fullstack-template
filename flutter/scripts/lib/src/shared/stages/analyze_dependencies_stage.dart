import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/shared/ports/module_graph_port.dart';
import 'package:scripts/src/shared/stages/pipeline_context.dart';

class AnalyzeDependenciesStage<T extends PipelineContext> implements Stage<T> {
  const AnalyzeDependenciesStage(this._moduleGraphPort);

  final ModuleGraphPort _moduleGraphPort;

  @override
  String get name => 'analyze-dependencies';

  @override
  Future<T> run(T context) async {
    context.dependencyReport = await _moduleGraphPort.analyzeDependencies(
      context.state,
    );
    return context;
  }
}
