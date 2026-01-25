import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/build_engine/domain/models/pipeline_context.dart';
import 'package:scripts/src/features/build_engine/domain/ports/module_graph_port.dart';

class AnalyzeDependenciesStage<T extends PipelineContext> implements Stage<T> {
  const AnalyzeDependenciesStage(this._moduleGraphPort);

  final ModuleGraphPort _moduleGraphPort;

  @override
  String get name => 'analyze-dependencies';

  @override
  Future<T> run(T context) async {
    context.dependencyReport = await _moduleGraphPort.analyzeDependencies(
      context.state,
      quiet: context.quiet,
    );
    return context;
  }
}
