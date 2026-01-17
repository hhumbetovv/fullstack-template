import 'package:scripts/src/features/build_engine/domain/models/module_graph_options.dart';
import 'package:scripts/src/features/build_engine/domain/models/pipeline_context.dart';

class ModuleGraphContext extends PipelineContext {
  ModuleGraphContext({
    required super.state,
    required this.options,
    super.quiet = false,
  });

  final ModuleGraphOptions options;
}
