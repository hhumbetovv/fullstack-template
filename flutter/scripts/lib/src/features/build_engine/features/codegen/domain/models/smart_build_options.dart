class SmartBuildOptions {
  const SmartBuildOptions({
    required this.verbose,
    required this.dryRun,
    required this.maxParallelBuilds,
    this.targetModule,
    this.optimized = false,
    this.autoParallel = false,
  });

  final bool verbose;
  final bool dryRun;
  final int maxParallelBuilds;
  final String? targetModule;
  final bool optimized;
  final bool autoParallel;
}
