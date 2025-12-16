import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/shared/ports/module_graph_port.dart';
import 'package:scripts/src/shared/stages/pipeline_context.dart';

class DiscoverModulesStage<T extends PipelineContext> implements Stage<T> {
  const DiscoverModulesStage(this._moduleGraphPort);

  final ModuleGraphPort _moduleGraphPort;

  @override
  String get name => 'discover-modules';

  @override
  Future<T> run(T context) async {
    await _moduleGraphPort.discoverModules(context.state);
    return context;
  }
}
