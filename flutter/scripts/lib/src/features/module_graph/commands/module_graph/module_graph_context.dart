import 'package:scripts/src/features/module_graph/domain/models/module_graph_options.dart';
import 'package:scripts/src/shared/stages/pipeline_context.dart';

class ModuleGraphContext extends PipelineContext {
  ModuleGraphContext({
    required super.state,
    required this.options,
  });

  final ModuleGraphOptions options;
}
