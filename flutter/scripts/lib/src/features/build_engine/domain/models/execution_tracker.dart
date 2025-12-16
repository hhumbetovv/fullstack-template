import 'dart:io';

/// Tracks mutable data specific to an on-going smart build execution.
class ExecutionTracker {
  ExecutionTracker();

  final Map<String, BuildStatus> moduleBuildStatus = <String, BuildStatus>{};
  final Map<String, Process> modulePids = <String, Process>{};
  final Map<String, int> moduleBuildLevel = <String, int>{};
  final List<String> buildOrder = <String>[];
  final Set<String> currentlyBuilding = <String>{};

  void reset() {
    moduleBuildStatus.clear();
    modulePids.clear();
    moduleBuildLevel.clear();
    buildOrder.clear();
    currentlyBuilding.clear();
  }
}

/// Build status per module.
enum BuildStatus { pending, building, completed, failed }
