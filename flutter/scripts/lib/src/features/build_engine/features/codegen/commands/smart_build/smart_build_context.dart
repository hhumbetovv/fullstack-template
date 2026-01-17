import 'package:scripts/src/features/build_engine/domain/models/pipeline_context.dart';
import 'package:scripts/src/features/build_engine/features/codegen/domain/models/smart_build_options.dart';

class SmartBuildContext extends PipelineContext {
  SmartBuildContext({
    required super.state,
    required this.options,
    super.quiet = false,
  });

  final SmartBuildOptions options;
  bool skipBuild = false;
  String? skipReason;
}
