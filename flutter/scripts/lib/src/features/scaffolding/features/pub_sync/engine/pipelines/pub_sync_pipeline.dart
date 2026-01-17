import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/scaffolding/domain/adapters/module_config_service.dart';
import 'package:scripts/src/features/scaffolding/features/pub_sync/engine/pipelines/pub_sync/pub_sync_context.dart';
import 'package:scripts/src/features/scaffolding/features/pub_sync/engine/stages/pub_sync/pub_get_stage.dart';
import 'package:scripts/src/features/scaffolding/features/pub_sync/engine/stages/pub_sync/summary_stage.dart';
import 'package:scripts/src/features/scaffolding/features/pub_sync/engine/stages/pub_sync/sync_modules_stage.dart';

class PubSyncPipeline {
  PubSyncPipeline({
    required ModuleConfigService service,
  })  : _syncStage = SyncModulesStage(service),
        _summaryStage = SummaryStage(),
        _pubGetStage = PubGetStage();

  final SyncModulesStage _syncStage;
  final SummaryStage _summaryStage;
  final PubGetStage _pubGetStage;

  Future<PubSyncContext> run(PubSyncContext context) {
    return StageRunner<PubSyncContext>(
      stages: <Stage<PubSyncContext>>[
        _syncStage,
        _summaryStage,
        _pubGetStage,
      ],
    ).run(context);
  }
}
