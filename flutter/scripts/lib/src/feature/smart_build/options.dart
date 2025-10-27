class SmartBuildOptions {
  const SmartBuildOptions({
    required this.verbose,
    required this.dryRun,
    required this.maxParallelBuilds,
    this.targetModule,
  });

  final bool verbose;
  final bool dryRun;
  final int maxParallelBuilds;
  final String? targetModule;
}
