import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/build_engine/domain/models/pipeline_context.dart';
import 'package:scripts/src/features/build_engine/domain/ports/module_graph_port.dart';

class GenerateGraphStage<T extends PipelineContext> implements Stage<T> {
  const GenerateGraphStage(this._moduleGraphPort);

  final ModuleGraphPort _moduleGraphPort;

  @override
  String get name => 'generate-graph';

  @override
  Future<T> run(T context) async {
    context.graphReport = await _moduleGraphPort.generateGraphFiles(
      context.state,
    );
    return context;
  }
}
