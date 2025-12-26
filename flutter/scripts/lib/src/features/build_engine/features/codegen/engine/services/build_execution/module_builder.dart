import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:common_tooling/tooling.dart';
import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/features/build_engine/domain/models/build_state.dart';

class ModuleBuildRunner {
  const ModuleBuildRunner();

  Future<ModuleBuildResult> run(BuildState state, String moduleName) async {
    final modulePath = state.workspaceSnapshot.modulePaths[moduleName]!;
    final logFile = '${state.buildLogsDir}/build_$moduleName.log';

    state.moduleBuildStatus[moduleName] = BuildStatus.building;

    if (state.dryRun) {
      state.moduleBuildStatus[moduleName] = BuildStatus.completed;
      return const ModuleBuildResult.success();
    }

    final buildArgs = [
      'run',
      'build_runner',
      'build',
      '-d',
      '--build-filter=lib/**',
      '--build-filter=assets/**',
    ];

    final logWriter = await _BufferedLogWriter.create(logFile)
      ..writeln('=== Build started at ${DateTime.now().toIso8601String()} ===')
      ..writeln('Module: $moduleName')
      ..writeln('Path: $modulePath')
      ..writeln('Command: dart ${buildArgs.join(' ')}')
      ..writeln('===================================\n');

    final buildProcess = await startDartCommand(
      buildArgs,
      workingDirectory: modulePath,
    );

    state.modulePids[moduleName] = buildProcess;
    state.currentlyBuilding.add(moduleName);

    final subscriptions = <StreamSubscription<List<int>>>[];
    void capture(Stream<List<int>> source) {
      final subscription = source.listen(logWriter.add);
      subscriptions.add(subscription);
    }

    capture(buildProcess.stdout);
    capture(buildProcess.stderr);

    var exitCode = 1;
    try {
      exitCode = await buildProcess.exitCode;
    } finally {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      logWriter.writeln(
        '\n=== Build finished at ${DateTime.now().toIso8601String()} ===',
      );
      final statusLabel = exitCode == 0 ? 'success' : 'failure';
      logWriter.writeln('=== Build status: $statusLabel ===');
      await logWriter.close();
    }

    state.modulePids.remove(moduleName);
    state.currentlyBuilding.remove(moduleName);

    if (exitCode == 0) {
      state.moduleBuildStatus[moduleName] = BuildStatus.completed;
      return const ModuleBuildResult.success();
    }

    state.moduleBuildStatus[moduleName] = BuildStatus.failed;
    Logger.error('❌ $moduleName failed. See log: $logFile');

    if (state.verbose) {
      try {
        final logContent = await File(logFile).readAsString();
        final lines = logContent.split('\n');
        final lastLines = lines.skip(lines.length - 6).take(5);
        Logger.error('Last lines from build log:');
        for (final line in lastLines) {
          if (line.trim().isNotEmpty) {
            Logger.error('   $line');
          }
        }
      } on Object catch (e) {
        Logger.debug('Error reading log file: $e');
      }
    }

    return ModuleBuildResult.failure(logFile: logFile);
  }
}

class _BufferedLogWriter {
  _BufferedLogWriter._(this._sink);

  final IOSink _sink;
  final _buffer = BytesBuilder(copy: false);
  static const int _flushThreshold = 16 * 1024;

  static Future<_BufferedLogWriter> create(String path) async {
    final sink = File(path).openWrite();
    return _BufferedLogWriter._(sink);
  }

  void add(List<int> chunk) {
    _buffer.add(chunk);
    if (_buffer.length >= _flushThreshold) {
      _drainBuffer();
    }
  }

  void writeString(String data) => add(utf8.encode(data));

  void writeln(String line) => writeString('$line\n');

  void _drainBuffer() {
    if (_buffer.isEmpty) {
      return;
    }
    _sink.add(_buffer.takeBytes());
  }

  Future<void> close() async {
    _drainBuffer();
    await _sink.flush();
    await _sink.close();
  }
}

class ModuleBuildResult {
  const ModuleBuildResult._({
    required this.succeeded,
    this.logFile,
  });

  const ModuleBuildResult.success() : this._(succeeded: true);

  const ModuleBuildResult.failure({required String logFile})
    : this._(succeeded: false, logFile: logFile);

  final bool succeeded;
  final String? logFile;
}
