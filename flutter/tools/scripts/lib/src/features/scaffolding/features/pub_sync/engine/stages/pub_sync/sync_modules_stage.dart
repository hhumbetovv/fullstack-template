import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/scaffolding/domain/adapters/module_config_service.dart';
import 'package:scripts/src/features/scaffolding/features/pub_sync/engine/pipelines/pub_sync/pub_sync_context.dart';

class SyncModulesStage implements Stage<PubSyncContext> {
  SyncModulesStage(this._service);

  final ModuleConfigService _service;

  @override
  String get name => 'sync-modules';

  @override
  Future<PubSyncContext> run(PubSyncContext context) async {
    context.summary = await _service.syncModules(options: context.options);
    return context;
  }
}
