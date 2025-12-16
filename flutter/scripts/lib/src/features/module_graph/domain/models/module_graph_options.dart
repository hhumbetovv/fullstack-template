class ModuleGraphOptions {
  const ModuleGraphOptions({
    required this.verbose,
    required this.maxParallelBuilds,
  });

  final bool verbose;
  final int maxParallelBuilds;
}
