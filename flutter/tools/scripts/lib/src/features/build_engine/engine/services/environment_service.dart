import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/features/build_engine/domain/models/build_state.dart';
import 'package:tools_common/tooling.dart';

class EnvironmentService {
  const EnvironmentService();

  Future<void> validate() async {
    Logger.debug('Validating environment...');

    try {
      await ensureDartOrFvm(requirePubspec: true);
    } on ToolchainException catch (error) {
      throw SmartBuildException(error.message);
    }

    Logger.debug('Environment validation passed');
  }

  Future<void> cleanup(BuildState state) async {
    Logger.warning('🛑 Interrupt received, cleaning up...');

    for (final entry in state.modulePids.entries) {
      try {
        Logger.debug(
          'Killing build process for ${entry.key} (PID: ${entry.value.pid})',
        );
        entry.value.kill();
      } on Object catch (e) {
        Logger.debug('Error killing process for ${entry.key}: $e');
      }
    }

    Logger.info('Cleanup completed');
  }
}
