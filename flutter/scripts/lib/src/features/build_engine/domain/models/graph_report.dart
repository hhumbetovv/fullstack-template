class GraphSummary {
  const GraphSummary({
    required this.totalModules,
    required this.totalDependencies,
    required this.modulesWithUnused,
  });

  final int totalModules;
  final int totalDependencies;
  final Set<String> modulesWithUnused;
}

class GraphFile {
  const GraphFile({
    required this.path,
    required this.title,
  });

  final String path;
  final String title;
}

class GraphReport {
  const GraphReport({
    required this.summary,
    required this.outputs,
  });

  final GraphSummary summary;
  final List<GraphFile> outputs;
}
