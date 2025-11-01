import 'dart:io';

enum BuildStatus { pending, building, completed, failed }

class BuildState {
  Map<String, String> modulePaths = {};
  Map<String, String> allModulePaths = {};
  Map<String, Set<String>> moduleDependencies = {};
  Map<String, Set<String>> allModuleDependencies = {};
  Map<String, Set<String>> moduleUnusedDependencies = {};
  Map<String, BuildStatus> moduleBuildStatus = {};
  Map<String, Process> modulePids = {};
  Map<String, int> moduleBuildLevel = {};
  List<String> buildOrder = [];
  Set<String> currentlyBuilding = <String>{};
  int maxParallelBuilds = 8;
  bool verbose = false;
  bool dryRun = false;
  String buildLogsDir = 'build_logs';
  String? targetModule;
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
