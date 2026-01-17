class BuildWave {
  const BuildWave({
    required this.level,
    required this.modules,
  });

  final int level;
  final List<String> modules;
}

class BuildPlan {
  const BuildPlan({
    required this.waves,
    required this.order,
  });

  final List<BuildWave> waves;
  final List<String> order;
}
