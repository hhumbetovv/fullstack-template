import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;

import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/features/build_engine/domain/models/build_state.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/build_execution/log_manager.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/build_execution/module_builder.dart';

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

    final dependencyTracker = _DependencyTracker.build(state);
    final readyQueue = <_ReadyModule>[];
    final readySet = <String>{};
    final runningModules = <String>{};
    final waveAnnouncements = <int>{};
    final completionEvents = ListQueue<_BuildCompletion>();
    Completer<void>? completionSignal;

    void _notifyCompletion(_BuildCompletion completion) {
      completionEvents.addLast(completion);
      if (completionSignal != null && !completionSignal!.isCompleted) {
        completionSignal!.complete();
      }
      completionSignal = null;
    }

    Future<_BuildCompletion> _waitForNextCompletion() async {
      if (completionEvents.isEmpty) {
        completionSignal ??= Completer<void>();
        await completionSignal!.future;
      }
      return completionEvents.removeFirst();
    }

    void _enqueueReadyModule(String moduleName, {String? reason}) {
      if (state.moduleBuildStatus[moduleName] != BuildStatus.pending) {
        return;
      }
      if (dependencyTracker.hasPendingDependencies(moduleName)) {
        return;
      }
      if (!readySet.add(moduleName)) {
        return;
      }

      final wave = state.moduleBuildLevel[moduleName] ?? 0;
      readyQueue
        ..add(_ReadyModule(moduleName, wave))
        ..sort();

      if (reason != null) {
        Logger.info('🔓 $moduleName is now ready (unblocked by $reason).');
      } else if (state.verbose) {
        Logger.debug('Ready: $moduleName (wave $wave)');
      }
    }

    void _scheduleModule(_ReadyModule readyModule) {
      readySet.remove(readyModule.name);
      runningModules.add(readyModule.name);

      if (waveAnnouncements.add(readyModule.wave)) {
        _blankLine();
        Logger.info('🌊 Activating Wave ${readyModule.wave} (overlap enabled)');
        Logger.info('--------------------------------');
      }

      final dependencies =
          (state.moduleDependencies[readyModule.name] ?? <String>{}).toList()
            ..sort();
      final depDescription = dependencies.isEmpty
          ? 'no deps'
          : 'deps: ${dependencies.join(', ')}';
      Logger.info(
        '⚙️ Launching ${readyModule.name} (wave ${readyModule.wave}) | $depDescription',
      );

      try {
        final future = _moduleBuilder
            .run(state, readyModule.name)
            .then(
              (result) =>
                  _BuildCompletion(readyModule.name, readyModule.wave, result),
            );
        future.then(_notifyCompletion);
      } on Object catch (error, stackTrace) {
        Logger.error(
          'Build task crashed before starting for ${readyModule.name}: $error',
        );
        if (state.verbose) {
          developer.log('$stackTrace');
        }
        state.moduleBuildStatus[readyModule.name] = BuildStatus.failed;
        runningModules.remove(readyModule.name);
        final fallbackLog =
            '${state.buildLogsDir}/build_${readyModule.name}.log';
        _notifyCompletion(
          _BuildCompletion(
            readyModule.name,
            readyModule.wave,
            ModuleBuildResult.failure(logFile: fallbackLog),
          ),
        );
      }
    }

    for (final module in state.buildOrder) {
      _enqueueReadyModule(module);
    }

    while (completed < totalModules) {
      while (runningModules.length < state.maxParallelBuilds &&
          readyQueue.isNotEmpty) {
        final readyModule = readyQueue.removeAt(0);
        _scheduleModule(readyModule);
      }

      if (runningModules.isEmpty) {
        if (readyQueue.isEmpty) {
          _logBuildStall(state, dependencyTracker.blockedByFailure);
          return false;
        }
        continue;
      }

      final completion = await _waitForNextCompletion();
      runningModules.remove(completion.moduleName);

      final succeeded = completion.result.succeeded;
      if (succeeded) {
        completed++;
        Logger.success('✅ ${completion.moduleName} finished');
        for (final dependent in dependencyTracker.dependentsOf(
          completion.moduleName,
        )) {
          final remaining = dependencyTracker.decrementDependency(dependent);
          if (remaining <= 0) {
            _enqueueReadyModule(dependent, reason: completion.moduleName);
          } else if (state.verbose) {
            Logger.debug('   $dependent awaiting $remaining more dependencies');
          }
        }
      } else {
        failed++;
        completed++;
        Logger.error('❌ ${completion.moduleName} failed');
        for (final dependent in dependencyTracker.dependentsOf(
          completion.moduleName,
        )) {
          dependencyTracker.markBlockedByFailure(
            dependent,
            completion.moduleName,
          );
        }
      }

      final inProgress = runningModules.length;
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

  void _logBuildStall(
    BuildState state,
    Map<String, Set<String>> blockedByFailure,
  ) {
    Logger.error(
      'Build process stalled. Some modules cannot be built due to failed dependencies.',
    );

    for (final moduleName in state.buildOrder) {
      if (state.moduleBuildStatus[moduleName] == BuildStatus.pending) {
        Logger.error('   Stuck: $moduleName');
        final deps = state.moduleDependencies[moduleName] ?? <String>{};
        final failedDeps = blockedByFailure[moduleName];
        if (failedDeps != null && failedDeps.isNotEmpty) {
          for (final dep in failedDeps) {
            Logger.error('      → Blocked by failed: $dep');
          }
          continue;
        }
        for (final dep in deps) {
          final status = state.moduleBuildStatus[dep];
          if (status != BuildStatus.completed) {
            Logger.error(
              '      → Awaiting: $dep (status: ${status ?? 'unknown'})',
            );
          }
        }
      }
    }
  }

  void _blankLine() => developer.log('');
}

class _ReadyModule implements Comparable<_ReadyModule> {
  const _ReadyModule(this.name, this.wave);

  final String name;
  final int wave;

  @override
  int compareTo(_ReadyModule other) {
    final waveComparison = wave.compareTo(other.wave);
    if (waveComparison != 0) {
      return waveComparison;
    }
    return name.compareTo(other.name);
  }
}

class _BuildCompletion {
  const _BuildCompletion(this.moduleName, this.wave, this.result);

  final String moduleName;
  final int wave;
  final ModuleBuildResult result;
}

class _DependencyTracker {
  _DependencyTracker({
    required this.remainingDependencies,
    required this.dependents,
  });

  final Map<String, int> remainingDependencies;
  final Map<String, List<String>> dependents;
  final Map<String, Set<String>> blockedByFailure = <String, Set<String>>{};

  static _DependencyTracker build(BuildState state) {
    final modules = state.buildOrder.toSet();
    final remaining = <String, int>{};
    final dependents = <String, List<String>>{};

    for (final module in state.buildOrder) {
      final deps = state.moduleDependencies[module] ?? <String>{};
      final filteredDeps = deps.where(modules.contains).toList();
      remaining[module] = filteredDeps.length;
      for (final dependency in filteredDeps) {
        dependents.putIfAbsent(dependency, () => <String>[]).add(module);
      }
    }

    return _DependencyTracker(
      remainingDependencies: remaining,
      dependents: dependents,
    );
  }

  List<String> dependentsOf(String module) =>
      dependents[module] ?? const <String>[];

  int decrementDependency(String module) {
    final current = remainingDependencies[module];
    if (current == null) {
      return 0;
    }
    final next = current - 1;
    remainingDependencies[module] = next;
    return next;
  }

  bool hasPendingDependencies(String module) =>
      (remainingDependencies[module] ?? 0) > 0;

  void markBlockedByFailure(String module, String failedDependency) {
    blockedByFailure
        .putIfAbsent(module, () => <String>{})
        .add(failedDependency);
  }
}
