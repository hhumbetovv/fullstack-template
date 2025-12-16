import 'package:scripts/src/features/codegen/domain/models/smart_build_options.dart';
import 'package:scripts/src/shared/stages/pipeline_context.dart';

class SmartBuildContext extends PipelineContext {
  SmartBuildContext({
    required super.state,
    required this.options,
  });

  final SmartBuildOptions options;
}
