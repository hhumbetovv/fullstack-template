import 'package:scripts/src/features/scaffolding/domain/adapters/module_config_service.dart';
import 'package:scripts/src/features/scaffolding/domain/models/module_config.dart';
import 'package:scripts/src/features/scaffolding/features/pub_sync/engine/pipelines/pub_sync/pub_sync_context.dart';
import 'package:scripts/src/features/scaffolding/features/pub_sync/engine/pipelines/pub_sync_pipeline.dart';

class PubSyncExecutor {
  PubSyncExecutor({required ModuleConfigService service}) : _service = service;

  final ModuleConfigService _service;

  Future<int> run({required ModuleSyncOptions options}) async {
    final pipeline = PubSyncPipeline(service: _service);
    final context = await pipeline.run(PubSyncContext(options: options));
    return context.exitCode;
  }
}
