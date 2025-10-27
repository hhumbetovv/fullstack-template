import 'dart:io';

import 'package:common_tooling/tooling.dart';

import 'context.dart';
import 'logging.dart';
import 'options.dart';

Future<void> validateEnvironment() async {
  Logger.debug('Validating environment...');

  try {
    await ensureDartOrFvm(requirePubspec: true);
  } on ToolchainException catch (error) {
    throw SmartBuildException(error.message);
  }

  Logger.debug('Environment validation passed');
}

void cleanup() {
  Logger.warning('🛑 Interrupt received, cleaning up...');

  for (final entry in state.modulePids.entries) {
    try {
      Logger.debug(
        'Killing build process for ${entry.key} (PID: ${entry.value.pid})',
      );
      entry.value.kill();
    } on Exception catch (e) {
      Logger.debug('Error killing process for ${entry.key}: $e');
    }
  }

  Logger.info('Cleanup completed');
  exit(130);
}
