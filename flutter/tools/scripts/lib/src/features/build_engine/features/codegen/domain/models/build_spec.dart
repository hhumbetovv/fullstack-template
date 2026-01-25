enum BuildPlatform { android, ios }

enum BuildMode { debug, release }

class BuildSpec {
  const BuildSpec({
    required this.platform,
    required this.mode,
    required this.flavor,
  });

  final BuildPlatform platform;
  final BuildMode mode;
  final String flavor;

  String get description =>
      '${platform.name} ${mode.name} $flavor'.toUpperCase();
}

List<BuildSpec> createBuildSpecs(
  Set<BuildPlatform> platforms,
  Set<BuildMode> modes,
  Set<String> flavors,
) {
  final specs = <BuildSpec>[
    for (final platform in platforms)
      for (final mode in modes)
        for (final flavor in flavors)
          BuildSpec(
            platform: platform,
            mode: mode,
            flavor: flavor,
          ),
  ]..sort(compareBuildSpecs);
  return specs;
}

BuildPlatform? parsePlatform(String value) {
  switch (value) {
    case 'android':
      return BuildPlatform.android;
    case 'ios':
      return BuildPlatform.ios;
  }
  return null;
}

BuildMode? parseMode(String value) {
  switch (value) {
    case 'debug':
      return BuildMode.debug;
    case 'release':
      return BuildMode.release;
  }
  return null;
}

int compareBuildSpecs(BuildSpec a, BuildSpec b) {
  final platformCompare = a.platform.index.compareTo(b.platform.index);
  if (platformCompare != 0) return platformCompare;
  final modeCompare = a.mode.index.compareTo(b.mode.index);
  if (modeCompare != 0) return modeCompare;
  return a.flavor.compareTo(b.flavor);
}
