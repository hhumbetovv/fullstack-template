part of 'package:scripts/src/services/build_execution_service.dart';

Future<void> setupBuildLogsInternal(BuildState state) async {
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
