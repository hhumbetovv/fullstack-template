import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;

import 'package:scripts/src/core/config/scripts_config.dart';
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
    var resolved = 0;
    var successfulModules = 0;
    var failed = 0;
    var skipped = 0;

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
    final waveQueues = <int, _WaveBucket>{};
    final waveOrder = ListQueue<_WaveBucket>();
    final moduleWeights = <String, int>{};
    final readySet = <String>{};
    final runningModules = <String>{};
    final waveAnnouncements = <int>{};
    final completionEvents = ListQueue<_BuildCompletion>();
    final parallelController = _ParallelController(state);
    Completer<void>? completionSignal;

    void notifyCompletion(_BuildCompletion completion) {
      completionEvents.addLast(completion);
      if (completionSignal != null && !completionSignal!.isCompleted) {
        completionSignal!.complete();
      }
      completionSignal = null;
    }

    Future<_BuildCompletion> waitForNextCompletion() async {
      if (completionEvents.isEmpty) {
        completionSignal ??= Completer<void>();
        await completionSignal!.future;
      }
      return completionEvents.removeFirst();
    }

    void enqueueReadyModule(String moduleName, {String? reason}) {
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
      final bucket = waveQueues.putIfAbsent(wave, () => _WaveBucket(wave));
      final weight = moduleWeights[moduleName] ??= _computeModuleWeight(
        state,
        moduleName,
      );
      bucket.add(moduleName, weight);
      if (!bucket.inRotation) {
        _insertWaveBucket(waveOrder, bucket);
      }

      if (reason != null && state.verbose) {
        Logger.debug('🔓 $moduleName is now ready (unblocked by $reason).');
      } else if (state.verbose) {
        Logger.debug('Ready: $moduleName (wave $wave)');
      }
    }

    _ReadyModule? takeNextReadyModule() {
      while (waveOrder.isNotEmpty) {
        final bucket = waveOrder.removeFirst();
        final entry = bucket.takeNext();
        if (entry == null) {
          bucket.inRotation = false;
          waveQueues.remove(bucket.wave);
          continue;
        }
        if (bucket.modules.isNotEmpty) {
          waveOrder.addLast(bucket);
        } else {
          bucket.inRotation = false;
          waveQueues.remove(bucket.wave);
        }
        readySet.remove(entry.name);
        return _ReadyModule(entry.name, bucket.wave, entry.weight);
      }
      return null;
    }

    void scheduleModule(_ReadyModule readyModule) {
      runningModules.add(readyModule.name);
      parallelController.recordStart(readyModule.name);

      if (waveAnnouncements.add(readyModule.wave) && state.verbose) {
        _blankLine();
        Logger.info('🌊 Activating Wave ${readyModule.wave} (overlap enabled)');
        Logger.info('--------------------------------');
      }

      if (state.verbose) {
        final dependencies = (state.moduleDependencies[readyModule.name] ?? <String>{}).toList()..sort();
        final depDescription = dependencies.isEmpty ? 'no deps' : 'deps: ${dependencies.join(', ')}';
        Logger.info(
          '⚙️ Launching ${readyModule.name} (wave ${readyModule.wave}) | $depDescription',
        );
      }

      try {
        _moduleBuilder
            .run(state, readyModule.name)
            .then(
              (result) => _BuildCompletion(readyModule.name, readyModule.wave, result),
            )
            .then(notifyCompletion);
      } on Object catch (error, stackTrace) {
        Logger.error(
          'Build task crashed before starting for ${readyModule.name}: $error',
        );
        if (state.verbose) {
          developer.log('$stackTrace');
        }
        state.moduleBuildStatus[readyModule.name] = BuildStatus.failed;
        runningModules.remove(readyModule.name);
        final fallbackLog = '${state.buildLogsDir}/build_${readyModule.name}.log';
        notifyCompletion(
          _BuildCompletion(
            readyModule.name,
            readyModule.wave,
            ModuleBuildResult.failure(logFile: fallbackLog),
          ),
        );
      }
    }

    for (final module in state.buildOrder) {
      enqueueReadyModule(module);
    }

    while (resolved < totalModules) {
      while (runningModules.length < parallelController.limit) {
        final readyModule = takeNextReadyModule();
        if (readyModule == null) {
          break;
        }
        scheduleModule(readyModule);
      }

      if (runningModules.isEmpty) {
        if (waveOrder.isEmpty) {
          _logBuildStall(state, dependencyTracker.blockedByFailure);
          return false;
        }
        continue;
      }

      final completion = await waitForNextCompletion();
      runningModules.remove(completion.moduleName);
      parallelController.recordCompletion(completion.moduleName);

      if (completion.result.succeeded) {
        resolved++;
        successfulModules++;
        for (final dependent in dependencyTracker.dependentsOf(
          completion.moduleName,
        )) {
          if (state.moduleBuildStatus[dependent] == BuildStatus.blocked) {
            continue;
          }
          final remaining = dependencyTracker.decrementDependency(dependent);
          if (remaining <= 0) {
            enqueueReadyModule(dependent, reason: completion.moduleName);
          } else if (state.verbose) {
            Logger.debug('   $dependent awaiting $remaining more dependencies');
          }
        }
      } else {
        failed++;
        resolved++;
        final newlySkipped = _blockDependents(
          state,
          dependencyTracker,
          completion.moduleName,
        );
        skipped += newlySkipped;
        resolved += newlySkipped;
      }

      if (state.verbose) {
        final inProgress = runningModules.length;
        final pending = totalModules - resolved;
        Logger.info(
          '📊 Progress: Successful: $successfulModules/$totalModules | Failed: $failed | Skipped: $skipped | In Progress: $inProgress | Pending: $pending | Slots: ${parallelController.limit}',
        );
      }
    }

    _blankLine();
    Logger.info('════════════════════════════════════');
    Logger.info('📊 Build Summary');
    Logger.info('════════════════════════════════════');
    _blankLine();

    final successful = successfulModules;
    Logger.info('   ✅ Successful: $successful');
    Logger.info('   ❌ Failed: $failed');
    Logger.info('   ⚠️ Skipped: $skipped');
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

    if (skipped > 0) {
      _blankLine();
      Logger.warning('Modules skipped due to failed dependencies:');
      for (final entry in dependencyTracker.blockedByFailure.entries) {
        if (state.moduleBuildStatus[entry.key] == BuildStatus.blocked) {
          Logger.warning('   • ${entry.key} ← ${entry.value.join(', ')}');
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

  int _blockDependents(
    BuildState state,
    _DependencyTracker dependencyTracker,
    String failedModule,
  ) {
    var skipped = 0;
    for (final dependent in dependencyTracker.dependentsOf(failedModule)) {
      dependencyTracker.markBlockedByFailure(
        dependent,
        failedModule,
      );
      if (state.moduleBuildStatus[dependent] == BuildStatus.pending) {
        state.moduleBuildStatus[dependent] = BuildStatus.blocked;
        skipped++;
        Logger.warning('⚠️ Skipping $dependent (blocked by $failedModule)');
      }
    }
    return skipped;
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

class _ReadyModule {
  const _ReadyModule(this.name, this.wave, this.weight);

  final String name;
  final int wave;
  final int weight;
}

class _BuildCompletion {
  const _BuildCompletion(this.moduleName, this.wave, this.result);

  final String moduleName;
  final int wave;
  final ModuleBuildResult result;
}

class _WaveBucket {
  _WaveBucket(this.wave);

  final int wave;
  final List<_ReadyEntry> modules = <_ReadyEntry>[];
  bool inRotation = false;

  void add(String name, int weight) {
    final entry = _ReadyEntry(name, weight);
    var index = 0;
    while (index < modules.length && weight <= modules[index].weight) {
      index++;
    }
    modules.insert(index, entry);
  }

  _ReadyEntry? takeNext() {
    if (modules.isEmpty) {
      return null;
    }
    return modules.removeAt(0);
  }
}

class _ReadyEntry {
  _ReadyEntry(this.name, this.weight);

  final String name;
  final int weight;
}

void _insertWaveBucket(ListQueue<_WaveBucket> order, _WaveBucket bucket) {
  bucket.inRotation = true;
  if (order.isEmpty) {
    order.add(bucket);
    return;
  }
  final temp = List<_WaveBucket>.from(order);
  order.clear();
  var inserted = false;
  for (final existing in temp) {
    if (!inserted && bucket.wave < existing.wave) {
      order.add(bucket);
      inserted = true;
    }
    order.add(existing);
  }
  if (!inserted) {
    order.add(bucket);
  }
}

int _computeModuleWeight(BuildState state, String moduleName) {
  final depCount = state.moduleDependencies[moduleName]?.length ?? 0;
  final packageCount = state.modulePackageDependencies[moduleName]?.length ?? 0;
  final wave = state.moduleBuildLevel[moduleName] ?? 0;
  final path = state.workspaceSnapshot.modulePaths[moduleName] ?? moduleName;
  final pathDepth = '/'.allMatches(path).length + 1;
  return depCount * 5 + packageCount * 2 + (100 - wave) + pathDepth;
}

class _DependencyTracker {
  _DependencyTracker({
    required this.remainingDependencies,
    required this.dependents,
  });

  factory _DependencyTracker.build(BuildState state) {
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

  final Map<String, int> remainingDependencies;
  final Map<String, List<String>> dependents;
  final Map<String, Set<String>> blockedByFailure = <String, Set<String>>{};

  List<String> dependentsOf(String module) => dependents[module] ?? const <String>[];

  int decrementDependency(String module) {
    final current = remainingDependencies[module];
    if (current == null) {
      return 0;
    }
    final next = current - 1;
    remainingDependencies[module] = next;
    return next;
  }

  bool hasPendingDependencies(String module) => (remainingDependencies[module] ?? 0) > 0;

  void markBlockedByFailure(String module, String failedDependency) {
    blockedByFailure.putIfAbsent(module, () => <String>{}).add(failedDependency);
  }
}

class _ParallelController {
  _ParallelController(this.state) : _limit = state.maxParallelBuilds;

  final BuildState state;
  int _limit;
  final Map<String, DateTime> _startTimes = <String, DateTime>{};
  final ListQueue<Duration> _recentDurations = ListQueue<Duration>();
  static const int _historySize = 6;
  static const Duration _fastThreshold = Duration(seconds: 20);
  static const Duration _slowThreshold = Duration(seconds: 90);

  int get limit => state.autoParallel ? _limit : state.maxParallelBuilds;

  void recordStart(String module) {
    if (!state.autoParallel) {
      return;
    }
    _startTimes[module] = DateTime.now();
  }

  void recordCompletion(String module) {
    if (!state.autoParallel) {
      return;
    }
    final start = _startTimes.remove(module);
    if (start == null) {
      return;
    }
    final duration = DateTime.now().difference(start);
    _recentDurations.addLast(duration);
    if (_recentDurations.length > _historySize) {
      _recentDurations.removeFirst();
    }
    _adjustLimit();
  }

  void _adjustLimit() {
    if (_recentDurations.isEmpty) {
      return;
    }
    final totalMillis = _recentDurations.fold<int>(
      0,
      (sum, item) => sum + item.inMilliseconds,
    );
    final avg = Duration(milliseconds: totalMillis ~/ _recentDurations.length);
    if (avg <= _fastThreshold && _limit < BuildEngineConfig.maxParallelAutoCeiling) {
      _limit++;
    } else if (avg >= _slowThreshold && _limit > BuildEngineConfig.maxParallelAutoFloor) {
      _limit--;
    }
  }
}
