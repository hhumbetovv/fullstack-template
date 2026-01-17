class DependencyReport {
  const DependencyReport({
    required this.moduleDependencies,
    required this.allDependencies,
    required this.unusedDependencies,
  });

  final Map<String, Set<String>> moduleDependencies;
  final Map<String, Set<String>> allDependencies;
  final Map<String, Set<String>> unusedDependencies;
}
