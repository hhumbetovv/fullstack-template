import 'package:scripts/src/core/state/build_state.dart';
import 'package:scripts/src/services/build_execution/build_scheduler.dart';
import 'package:scripts/src/services/build_execution/log_manager.dart';
import 'package:scripts/src/services/build_execution/module_builder.dart';

class BuildExecutionService {
  BuildExecutionService({
    BuildScheduler? scheduler,
    BuildLogManager? logManager,
    ModuleBuildRunner? moduleBuilder,
  }) : _scheduler =
           scheduler ??
           BuildScheduler(
             logManager: logManager ?? const BuildLogManager(),
             moduleBuilder: moduleBuilder ?? const ModuleBuildRunner(),
           );

  final BuildScheduler _scheduler;

  Future<bool> execute(BuildState state) => _scheduler.execute(state);
}
