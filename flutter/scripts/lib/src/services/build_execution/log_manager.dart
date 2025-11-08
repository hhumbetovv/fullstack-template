import 'dart:io';

import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/core/state/build_state.dart';

class BuildLogManager {
  const BuildLogManager();

  Future<void> prepareLogs(BuildState state) async {
    final logsDir = Directory(state.buildLogsDir);
    if (!logsDir.existsSync()) {
      await logsDir.create(recursive: true);
      Logger.debug('Created build logs directory: ${state.buildLogsDir}');
    }

    try {
      await for (final file in logsDir.list()) {
        if (file is File && file.path.endsWith('.log')) {
          await file.delete();
        }
      }
    } on Object catch (e) {
      Logger.debug('Error cleaning old logs: $e');
    }
  }
}
