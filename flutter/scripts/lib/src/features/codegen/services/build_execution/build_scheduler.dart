import 'dart:developer' as developer;

import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/features/codegen/domain/models/build_state.dart';
import 'package:scripts/src/features/codegen/services/build_execution/log_manager.dart';
import 'package:scripts/src/features/codegen/services/build_execution/module_builder.dart';

class BuildScheduler {
  BuildScheduler({
    required BuildLogManager logManager,
    required ModuleBuildRunner moduleBuilder,
  }) : _logManager = logManager,
       _moduleBuilder = moduleBuilder;

  final BuildLogManager _logManager;
  final ModuleBuildRunner _moduleBuilder;

  Future<bool> execute(BuildState state) async {
    Logger.info('🚀 Starting smart build process...');

    if (state.dryRun) {
      Logger.warning('DRY RUN MODE - No actual builds will be performed');
    }

    await _logManager.prepareLogs(state);

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
                _moduleBuilder.canBuild(state, moduleName),
          )
          .toList();

      var availableSlots = state.maxParallelBuilds - state.currentlyBuilding.length;
      if (availableSlots < 0) {
        availableSlots = 0;
      } else if (availableSlots > state.maxParallelBuilds) {
        availableSlots = state.maxParallelBuilds;
      }
      final scheduledModules =
          availableSlots == 0 ? <String>[] : buildsInWave.take(availableSlots).toList();

      if (state.currentlyBuilding.isEmpty && buildsInWave.isEmpty) {
        _logBuildStall(state);
        return false;
      }

      if (scheduledModules.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        continue;
      }

      currentWave = minWave;
      _blankLine();
      Logger.info('🌊 Starting Wave $currentWave');
      Logger.info('================================');

      await Future.wait(
        scheduledModules.map((module) => _moduleBuilder.run(state, module)),
      );

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

    _blankLine();
    Logger.info('════════════════════════════════════');
    Logger.info('📊 Build Summary');
    Logger.info('════════════════════════════════════');
    _blankLine();

    final successful = completed - failed;
    Logger.info('   ✅ Successful: $successful');
    Logger.info('   ❌ Failed: $failed');
    Logger.info('   📦 Total: $totalModules');

    if (failed > 0) {
      _blankLine();
      Logger.error('Failed modules:');
      for (final moduleName in state.buildOrder) {
        if (state.moduleBuildStatus[moduleName] == BuildStatus.failed) {
          Logger.error(
            '   • $moduleName → Check: ${state.buildLogsDir}/build_$moduleName.log',
          );
        }
      }
    }

    _blankLine();
    if (failed == 0) {
      Logger.success('🎉 All builds completed successfully!');
      return true;
    }

    Logger.error(
      '💥 Some builds failed. Check individual log files in ${state.buildLogsDir}/',
    );
    return false;
  }

  void _logBuildStall(BuildState state) {
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
  }

  void _blankLine() => developer.log('');
}
