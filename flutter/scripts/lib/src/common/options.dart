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

class ModuleGraphOptions {
  const ModuleGraphOptions({
    required this.verbose,
    required this.maxParallelBuilds,
  });

  final bool verbose;
  final int maxParallelBuilds;
}

class SmartBuildException implements Exception {
  SmartBuildException(this.message, {this.exitCode = 1});

  final String message;
  final int exitCode;

  @override
  String toString() => message;
}
