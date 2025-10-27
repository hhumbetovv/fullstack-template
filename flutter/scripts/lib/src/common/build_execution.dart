import 'dart:convert';
import 'dart:io';

import 'package:common_tooling/tooling.dart';

import 'context.dart';
import 'logging.dart';

Future<void> setupBuildLogs() async {
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
  } on Exception catch (e) {
    Logger.debug('Error cleaning old logs: $e');
  }
}

bool canBuildModule(String moduleName) {
  Logger.debug('Checking if $moduleName can be built...');

  final dependencies = state.moduleDependencies[moduleName] ?? <String>{};

  if (dependencies.isEmpty) {
    Logger.debug('   $moduleName has no dependencies, can build');
    return true;
  }

  for (final dep in dependencies) {
    if (state.moduleBuildStatus[dep] != BuildStatus.completed) {
      Logger.debug(
        '   $moduleName waiting for $dep (status: ${state.moduleBuildStatus[dep]})',
      );
      return false;
    }
  }

  Logger.debug('   $moduleName all dependencies satisfied, can build');
  return true;
}

Future<Map<String, dynamic>> buildModule(String moduleName) async {
  final modulePath = state.modulePaths[moduleName]!;
  final logFile = '${state.buildLogsDir}/build_$moduleName.log';

  Logger.building('Building $moduleName ($modulePath)...');
  state.moduleBuildStatus[moduleName] = BuildStatus.building;

  if (state.dryRun) {
    Logger.info('[DRY RUN] Would build: $moduleName');
    state.moduleBuildStatus[moduleName] = BuildStatus.completed;
    return {'success': true, 'moduleName': moduleName};
  }

  final logSink = File(logFile).openWrite()
    ..writeln('=== Build started at ${DateTime.now().toIso8601String()} ===')
    ..writeln('Module: $moduleName')
    ..writeln('Path: $modulePath')
    ..writeln('Command: dart run build_runner build -d')
    ..writeln('===================================\n');

  final buildProcess = await startDartCommand(
    ['run', 'build_runner', 'build', '-d'],
    workingDirectory: modulePath,
  );

  state.modulePids[moduleName] = buildProcess;
  state.currentlyBuilding.add(moduleName);

  buildProcess.stdout.transform(utf8.decoder).listen(logSink.write);
  buildProcess.stderr.transform(utf8.decoder).listen(logSink.write);

  final exitCode = await buildProcess.exitCode;

  logSink.writeln(
    '\n=== Build finished at ${DateTime.now().toIso8601String()} ===',
  );
  await logSink.close();

  state.modulePids.remove(moduleName);
  state.currentlyBuilding.remove(moduleName);

  if (exitCode == 0) {
    state.moduleBuildStatus[moduleName] = BuildStatus.completed;
    Logger.success('✅ $moduleName build completed');
    return {'success': true, 'moduleName': moduleName};
  } else {
    state.moduleBuildStatus[moduleName] = BuildStatus.failed;
    Logger.error('❌ $moduleName build failed (check $logFile)');

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
      } on Exception catch (e) {
        Logger.debug('Error reading log file: $e');
      }
    }

    return {'success': false, 'moduleName': moduleName};
  }
}

Future<bool> executeSmartBuild() async {
  Logger.info('🚀 Starting smart build process...');

  if (state.dryRun) {
    Logger.warning('DRY RUN MODE - No actual builds will be performed');
  }

  await setupBuildLogs();

  final totalModules = state.buildOrder.length;
  var completed = 0;
  var failed = 0;
  var currentWave = -1;

  Logger.info('Total modules to build: $totalModules');
  Logger.info('Max parallel builds: ${state.maxParallelBuilds}');

  while (completed < totalModules) {
    var minWave = 999;
    var allModulesBuilt = true;
    for (final moduleName in state.buildOrder) {
      if (state.moduleBuildStatus[moduleName] == BuildStatus.pending) {
        allModulesBuilt = false;
        final wave = state.moduleBuildLevel[moduleName] ?? 0;
        if (wave < minWave) {
          minWave = wave;
        }
      }
    }

    if (allModulesBuilt) break;

    final buildsInWave = state.buildOrder
        .where(
          (moduleName) =>
              state.moduleBuildStatus[moduleName] == BuildStatus.pending &&
              (state.moduleBuildLevel[moduleName] ?? 0) == minWave &&
              canBuildModule(moduleName),
        )
        .toList();

    if (state.currentlyBuilding.isEmpty && buildsInWave.isEmpty) {
      Logger.error(
        'Build process stalled. Some modules cannot be built due to failed dependencies.',
      );

      for (final moduleName in state.buildOrder) {
        if (state.moduleBuildStatus[moduleName] == BuildStatus.pending) {
          Logger.error('   Stuck: $moduleName');
          final deps = state.moduleDependencies[moduleName] ?? <String>{};
          for (final dep in deps) {
            if (state.moduleBuildStatus[dep] == BuildStatus.failed) {
              Logger.error('      → Blocked by failed: $dep');
            }
          }
        }
      }
      return false;
    }

    if (buildsInWave.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      continue;
    }

    currentWave = minWave;
    log('');
    Logger.info('🌊 Starting Wave $currentWave');
    Logger.info('================================');

    final buildFutures = <Future<Map<String, dynamic>>>[];
    for (final moduleName in buildsInWave) {
      buildFutures.add(buildModule(moduleName));
    }

    await Future.wait(buildFutures);

    completed = 0;
    failed = 0;
    for (final moduleName in state.buildOrder) {
      final status = state.moduleBuildStatus[moduleName]!;
      if (status == BuildStatus.completed) {
        completed++;
      } else if (status == BuildStatus.failed) {
        failed++;
        completed++;
      }
    }

    final inProgress = state.currentlyBuilding.length;
    final pending = totalModules - completed;
    Logger.info(
      '📊 Progress: Completed: ${completed - failed}/$totalModules | Failed: $failed | In Progress: $inProgress | Pending: $pending',
    );
  }

  log('');
  Logger.info('════════════════════════════════════');
  Logger.info('📊 Build Summary');
  Logger.info('════════════════════════════════════');
  log('');

  final successful = completed - failed;
  Logger.info('   ✅ Successful: $successful');
  Logger.info('   ❌ Failed: $failed');
  Logger.info('   📦 Total: $totalModules');

  if (failed > 0) {
    log('');
    Logger.error('Failed modules:');
    for (final moduleName in state.buildOrder) {
      if (state.moduleBuildStatus[moduleName] == BuildStatus.failed) {
        Logger.error(
          '   • $moduleName → Check: ${state.buildLogsDir}/build_$moduleName.log',
        );
      }
    }
  }

  log('');
  if (failed == 0) {
    Logger.success('🎉 All builds completed successfully!');
    return true;
  } else {
    Logger.error(
      '💥 Some builds failed. Check individual log files in ${state.buildLogsDir}/',
    );
    return false;
  }
}
