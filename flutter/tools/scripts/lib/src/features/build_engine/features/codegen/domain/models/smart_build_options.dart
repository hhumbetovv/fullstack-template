class SmartBuildOptions {
  const SmartBuildOptions({
    required this.verbose,
    required this.dryRun,
    required this.maxParallelBuilds,
    required this.mode,
    this.targetModule,
    this.optimized = false,
    this.autoParallel = false,
  });

  final bool verbose;
  final bool dryRun;
  final int maxParallelBuilds;
  final SmartBuildMode mode;
  final String? targetModule;
  final bool optimized;
  final bool autoParallel;
}

enum SmartBuildMode {
  error,
  gitChange,
  all,
}

extension SmartBuildModeLabel on SmartBuildMode {
  String get description => switch (this) {
    SmartBuildMode.error => 'error',
    SmartBuildMode.gitChange => 'git-change',
    SmartBuildMode.all => 'all',
  };
}

SmartBuildMode parseSmartBuildMode(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'error':
      return SmartBuildMode.error;
    case 'git':
    case 'git-change':
    case 'git_changes':
    case 'gitchange':
      return SmartBuildMode.gitChange;
    case 'all':
      return SmartBuildMode.all;
  }
  throw FormatException('Unsupported smart-build mode', raw);
}
