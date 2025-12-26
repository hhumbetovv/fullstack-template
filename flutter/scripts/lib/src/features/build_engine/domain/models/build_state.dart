import 'dart:io';

import 'package:scripts/src/core/config/scripts_config.dart';
import 'package:scripts/src/features/build_engine/domain/models/execution_tracker.dart';
import 'package:scripts/src/features/build_engine/domain/models/workspace_graph.dart';
import 'package:scripts/src/features/build_engine/domain/models/workspace_snapshot.dart';

export 'execution_tracker.dart' show BuildStatus;

/// Aggregates workspace discovery data and the mutable execution tracker.
class BuildState {
  BuildState();

  final WorkspaceGraph workspace = WorkspaceGraph();
  final ExecutionTracker execution = ExecutionTracker();
  WorkspaceSnapshot? _workspaceSnapshot;

  static int get maxParallelBuildsDefault =>
      BuildEngineConfig.maxParallelBuilds;
  static String get buildLogsDirDefault => BuildEngineConfig.buildLogsDir;
  int maxParallelBuilds = maxParallelBuildsDefault;
  bool verbose = false;
  bool dryRun = false;
  String buildLogsDir = buildLogsDirDefault;
  String? targetModule;
  bool optimized = false;
  bool autoParallel = false;

  Map<String, String> get modulePaths => workspace.modulePaths;
  Map<String, String> get allModulePaths => workspace.allModulePaths;
  Map<String, Set<String>> get moduleDependencies =>
      workspace.moduleDependencies;
  Map<String, Set<String>> get allModuleDependencies =>
      workspace.allModuleDependencies;
  Map<String, Set<String>> get moduleUnusedDependencies =>
      workspace.moduleUnusedDependencies;
  Map<String, Set<String>> get modulePackageDependencies =>
      workspace.modulePackageDependencies;
  Map<String, Set<String>> get moduleUnusedPackages =>
      workspace.moduleUnusedPackages;

  WorkspaceSnapshot get workspaceSnapshot =>
      _workspaceSnapshot ??= WorkspaceSnapshot.fromGraph(workspace);

  Map<String, BuildStatus> get moduleBuildStatus => execution.moduleBuildStatus;
  Map<String, Process> get modulePids => execution.modulePids;
  Map<String, int> get moduleBuildLevel => execution.moduleBuildLevel;
  List<String> get buildOrder => execution.buildOrder;
  set buildOrder(List<String> value) {
    execution.buildOrder
      ..clear()
      ..addAll(value);
  }

  Set<String> get currentlyBuilding => execution.currentlyBuilding;

  static int computeAutoParallelism() {
    final cpuCount = Platform.numberOfProcessors;
    if (cpuCount <= 0) {
      return maxParallelBuildsDefault;
    }
    final target = cpuCount <= 4 ? cpuCount : cpuCount - 1;
    const min = BuildEngineConfig.maxParallelAutoFloor;
    const max = BuildEngineConfig.maxParallelAutoCeiling;
    final clamped = target.clamp(min, max);
    return clamped;
  }

  void resetWorkspace() {
    workspace.reset();
    execution.reset();
    _workspaceSnapshot = null;
  }

  void invalidateWorkspaceSnapshot() {
    _workspaceSnapshot = null;
  }

  BuildState clone() {
    final copy = BuildState()
      ..maxParallelBuilds = maxParallelBuilds
      ..verbose = verbose
      ..dryRun = dryRun
      ..buildLogsDir = buildLogsDir
      ..targetModule = targetModule
      ..optimized = optimized
      ..autoParallel = autoParallel;

    void copyStringMap(Map<String, String> source, Map<String, String> target) {
      target
        ..clear()
        ..addAll(source);
    }

    void copySetMap(
      Map<String, Set<String>> source,
      Map<String, Set<String>> target,
    ) {
      target
        ..clear()
        ..addEntries(
          source.entries.map(
            (entry) => MapEntry(entry.key, Set<String>.from(entry.value)),
          ),
        );
    }

    copyStringMap(workspace.modulePaths, copy.workspace.modulePaths);
    copyStringMap(workspace.allModulePaths, copy.workspace.allModulePaths);
    copySetMap(workspace.moduleDependencies, copy.workspace.moduleDependencies);
    copySetMap(
      workspace.allModuleDependencies,
      copy.workspace.allModuleDependencies,
    );
    copySetMap(
      workspace.moduleUnusedDependencies,
      copy.workspace.moduleUnusedDependencies,
    );
    copySetMap(
      workspace.modulePackageDependencies,
      copy.workspace.modulePackageDependencies,
    );
    copySetMap(
      workspace.moduleUnusedPackages,
      copy.workspace.moduleUnusedPackages,
    );

    copy.execution.moduleBuildStatus.addAll(execution.moduleBuildStatus);
    copy.execution.moduleBuildLevel.addAll(execution.moduleBuildLevel);
    copy.execution.buildOrder.addAll(execution.buildOrder);

    return copy;
  }
}

class BuildStateStore {
  BuildStateStore();

  BuildState _state = BuildState();

  BuildState get state => _state;

  BuildState configure({
    bool verbose = false,
    bool dryRun = false,
    int? maxParallelBuilds,
    String? targetModule,
    bool optimized = false,
    bool autoParallel = false,
  }) => _state = BuildState()
    ..verbose = verbose
    ..dryRun = dryRun
    ..maxParallelBuilds =
        maxParallelBuilds ?? BuildState.maxParallelBuildsDefault
    ..targetModule = targetModule
    ..optimized = optimized
    ..autoParallel = autoParallel;

  void reset() {
    _state = BuildState();
  }
}
