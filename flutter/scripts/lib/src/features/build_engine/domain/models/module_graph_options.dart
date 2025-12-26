class ModuleGraphOptions {
  const ModuleGraphOptions({
    required this.verbose,
    required this.maxParallelBuilds,
    this.quiet = false,
  });

  final bool verbose;
  final int maxParallelBuilds;
  final bool quiet;
}
