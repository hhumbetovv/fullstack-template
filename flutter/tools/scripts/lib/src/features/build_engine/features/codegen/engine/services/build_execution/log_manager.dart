import 'dart:io';

import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/features/build_engine/domain/models/build_state.dart';

class BuildLogManager {
  const BuildLogManager();

  Future<void> prepareLogs(BuildState state) async {
    final logsDir = Directory(state.buildLogsDir);
    if (!logsDir.existsSync()) {
      await logsDir.create(recursive: true);
      Logger.debug('Created build logs directory: ${state.buildLogsDir}');
    }
    // Do not delete existing logs; git-change relies on historical timestamps.
  }
}
