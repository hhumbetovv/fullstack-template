import 'package:scripts/src/features/build_engine/domain/models/build_state.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/build_execution/build_scheduler.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/build_execution/log_manager.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/build_execution/module_builder.dart';

class BuildExecutionService {
  BuildExecutionService({
    BuildScheduler? scheduler,
    BuildLogManager? logManager,
    ModuleBuildRunner? moduleBuilder,
  }) : _logManager = logManager ?? const BuildLogManager(),
       _moduleBuilder = moduleBuilder ?? const ModuleBuildRunner(),
       _legacySchedulerOverride = scheduler;

  final BuildLogManager _logManager;
  final ModuleBuildRunner _moduleBuilder;
  final BuildScheduler? _legacySchedulerOverride;

  late final BuildScheduler _scheduler =
      _legacySchedulerOverride ??
      BuildScheduler(
        logManager: _logManager,
        moduleBuilder: _moduleBuilder,
      );

  Future<bool> execute(
    BuildState state, {
    required bool optimized,
    Future<bool> Function(String moduleName)? onModuleComplete,
  }) => _scheduler.execute(
    state,
    onModuleComplete: onModuleComplete,
  );
}
