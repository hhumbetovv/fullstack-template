import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/shared/services/environment_service.dart';
import 'package:scripts/src/shared/stages/pipeline_context.dart';

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
