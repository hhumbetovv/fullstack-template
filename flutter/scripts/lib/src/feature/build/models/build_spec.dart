enum BuildPlatform { android, ios }

enum BuildMode { debug, release }

enum BuildFlavor { dev, prod }

class BuildSpec {
  const BuildSpec({
    required this.platform,
    required this.mode,
    required this.flavor,
  });

  final BuildPlatform platform;
  final BuildMode mode;
  final BuildFlavor flavor;

  String get description =>
      '${platform.name} ${mode.name} ${flavor.name}'.toUpperCase();
}

List<BuildSpec> createBuildSpecs(
  Set<BuildPlatform> platforms,
  Set<BuildMode> modes,
  Set<BuildFlavor> flavors,
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
  ]..sort(_compareSpecs);
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

BuildFlavor? parseFlavor(String value) {
  switch (value) {
    case 'dev':
      return BuildFlavor.dev;
    case 'prod':
      return BuildFlavor.prod;
  }
  return null;
}

int _compareSpecs(BuildSpec a, BuildSpec b) {
  final platformCompare = a.platform.index.compareTo(b.platform.index);
  if (platformCompare != 0) return platformCompare;
  final modeCompare = a.mode.index.compareTo(b.mode.index);
  if (modeCompare != 0) return modeCompare;
  return a.flavor.index.compareTo(b.flavor.index);
}
