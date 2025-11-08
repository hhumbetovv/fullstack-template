import 'dart:collection';

import 'package:scripts/src/core/state/workspace_graph.dart';

class WorkspaceSnapshot {
  WorkspaceSnapshot({
    required Map<String, String> modulePaths,
    required Map<String, String> allModulePaths,
  }) : modulePaths = UnmodifiableMapView(Map.of(modulePaths)),
       allModulePaths = UnmodifiableMapView(Map.of(allModulePaths));

  factory WorkspaceSnapshot.fromGraph(WorkspaceGraph graph) {
    return WorkspaceSnapshot(
      modulePaths: graph.modulePaths,
      allModulePaths: graph.allModulePaths,
    );
  }

  final Map<String, String> modulePaths;
  final Map<String, String> allModulePaths;
}
