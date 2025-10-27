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

BuildState state = BuildState();

BuildState configureState({
  bool verbose = false,
  bool dryRun = false,
  int maxParallelBuilds = 4,
  String? targetModule,
}) {
  return state = BuildState()
    ..verbose = verbose
    ..dryRun = dryRun
    ..maxParallelBuilds = maxParallelBuilds
    ..targetModule = targetModule;
}

void resetState() {
  state
    ..modulePaths = {}
    ..allModulePaths = {}
    ..moduleDependencies = {}
    ..allModuleDependencies = {}
    ..moduleUnusedDependencies = {}
    ..moduleBuildStatus = {}
    ..modulePids = {}
    ..moduleBuildLevel = {}
    ..buildOrder = []
    ..currentlyBuilding = <String>{}
    ..maxParallelBuilds = 8
    ..verbose = false
    ..dryRun = false
    ..buildLogsDir = 'build_logs'
    ..targetModule = null;
}
