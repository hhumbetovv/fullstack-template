part of 'package:scripts/src/services/build_execution_service.dart';

Future<bool> executeSmartBuildInternal(BuildState state) async {
  Logger.info('🚀 Starting smart build process...');

  if (state.dryRun) {
    Logger.warning('DRY RUN MODE - No actual builds will be performed');
  }

  await setupBuildLogsInternal(state);

  final totalModules = state.buildOrder.length;
  var completed = 0;
  var failed = 0;
  var currentWave = -1;

  Logger.info('Total modules to build: $totalModules');
  Logger.info('Max parallel builds: ${state.maxParallelBuilds}');

  if (state.verbose) {
    Logger.debug('Build order (${state.buildOrder.length} modules):');
    for (final module in state.buildOrder) {
      Logger.debug(
        '   • $module (wave ${state.moduleBuildLevel[module] ?? '?'} )',
      );
    }
  }

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
              canBuildModuleInternal(state, moduleName),
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
      buildFutures.add(buildModuleInternal(state, moduleName));
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
