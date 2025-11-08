import 'dart:io';

import 'package:scripts/src/core/state/execution_tracker.dart';
import 'package:scripts/src/core/state/workspace_graph.dart';
import 'package:scripts/src/core/state/workspace_snapshot.dart';

export 'execution_tracker.dart' show BuildStatus;

/// Aggregates workspace discovery data and the mutable execution tracker.
class BuildState {
  BuildState();

  final WorkspaceGraph workspace = WorkspaceGraph();
  final ExecutionTracker execution = ExecutionTracker();
  WorkspaceSnapshot? _workspaceSnapshot;

  int maxParallelBuilds = 8;
  bool verbose = false;
  bool dryRun = false;
  String buildLogsDir = 'build_logs';
  String? targetModule;

  Map<String, String> get modulePaths => workspace.modulePaths;
  Map<String, String> get allModulePaths => workspace.allModulePaths;
  Map<String, Set<String>> get moduleDependencies =>
      workspace.moduleDependencies;
  Map<String, Set<String>> get allModuleDependencies =>
      workspace.allModuleDependencies;
  Map<String, Set<String>> get moduleUnusedDependencies =>
      workspace.moduleUnusedDependencies;

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

  void resetWorkspace() {
    workspace.reset();
    execution.reset();
    _workspaceSnapshot = null;
  }

  void invalidateWorkspaceSnapshot() {
    _workspaceSnapshot = null;
  }
}

class BuildStateStore {
  BuildStateStore();

  BuildState _state = BuildState();

  BuildState get state => _state;

  BuildState configure({
    bool verbose = false,
    bool dryRun = false,
    int maxParallelBuilds = 4,
    String? targetModule,
  }) => _state = BuildState()
    ..verbose = verbose
    ..dryRun = dryRun
    ..maxParallelBuilds = maxParallelBuilds
    ..targetModule = targetModule;

  void reset() {
    _state = BuildState();
  }
}
