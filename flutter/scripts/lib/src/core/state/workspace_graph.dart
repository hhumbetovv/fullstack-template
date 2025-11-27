/// Holds workspace discovery results (paths and dependency graph data).
class WorkspaceGraph {
  WorkspaceGraph();

  final Map<String, String> modulePaths = <String, String>{};
  final Map<String, String> allModulePaths = <String, String>{};
  final Map<String, Set<String>> moduleDependencies = <String, Set<String>>{};
  final Map<String, Set<String>> allModuleDependencies =
      <String, Set<String>>{};
  final Map<String, Set<String>> moduleUnusedDependencies =
      <String, Set<String>>{};
  final Map<String, Set<String>> modulePackageDependencies =
      <String, Set<String>>{};
  final Map<String, Set<String>> moduleUnusedPackages = <String, Set<String>>{};

  void reset() {
    modulePaths.clear();
    allModulePaths.clear();
    moduleDependencies.clear();
    allModuleDependencies.clear();
    moduleUnusedDependencies.clear();
    modulePackageDependencies.clear();
    moduleUnusedPackages.clear();
  }
}
