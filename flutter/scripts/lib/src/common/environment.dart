import 'dart:io';

import 'context.dart';
import 'logging.dart';
import 'options.dart';

Future<void> validateEnvironment() async {
  Logger.debug('Validating environment...');

  try {
    await Process.run('which', ['dart']);
  } on Exception catch (_) {
    try {
      await Process.run('which', ['fvm']);
    } on Exception catch (_) {
      throw SmartBuildException(
        "Neither 'dart' nor 'fvm' command found. Please ensure Flutter is installed.",
      );
    }
  }

  final rootPubspec = File('pubspec.yaml');
  if (!rootPubspec.existsSync()) {
    throw SmartBuildException(
      'No pubspec.yaml found in current directory. Please run from Flutter project root.',
    );
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
