import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/build_engine/domain/models/pipeline_context.dart';
import 'package:scripts/src/features/build_engine/engine/services/environment_service.dart';

class ValidateEnvStage<T extends PipelineContext> implements Stage<T> {
  const ValidateEnvStage(this._environmentService);

  final EnvironmentService _environmentService;

  @override
  String get name => 'validate-env';

  @override
  Future<T> run(T context) async {
    await _environmentService.validate();
    return context;
  }
}
