import 'package:args/args.dart';
import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/domain/models/build_spec.dart';

class BuildCommandOptions {
  const BuildCommandOptions({
    required this.keepKeyProperties,
    required this.requestAndroidAab,
    required this.requestAndroidApk,
    required this.requestIosIpa,
    required this.requestIosApp,
    required this.obfuscateAndroid,
    required this.splitDebugInfo,
    required this.splitDebugInfoPath,
    required this.applyTargetPlatform,
    required this.targetPlatform,
    required this.platforms,
    required this.modes,
    required this.flavors,
  });

  final bool keepKeyProperties;
  final bool requestAndroidAab;
  final bool requestAndroidApk;
  final bool requestIosIpa;
  final bool requestIosApp;
  final bool obfuscateAndroid;
  final bool splitDebugInfo;
  final String splitDebugInfoPath;
  final bool applyTargetPlatform;
  final String targetPlatform;
  final Set<BuildPlatform> platforms;
  final Set<BuildMode> modes;
  final Set<BuildFlavor> flavors;
}

BuildCommandOptions parseBuildCommandArgs(ArgResults? argResults) {
  final keepKeyProperties =
      argResults?['keep-key-properties'] as bool? ?? false;
  final requestAndroidAab = argResults?['android-aab'] as bool? ?? false;
  final requestAndroidApk = argResults?['android-apk'] as bool? ?? false;
  final requestIosIpa = argResults?['ios-ipa'] as bool? ?? false;
  final requestIosApp = argResults?['ios-app'] as bool? ?? false;
  final obfuscateAndroid = argResults?['obfuscate'] as bool? ?? true;
  final splitDebugInfo = argResults?['split-debug-info'] as bool? ?? true;
  final splitDebugInfoPathRaw =
      (argResults?['split-debug-info-path'] as String? ??
              './android/app/release')
          .trim();
  final applyTargetPlatform =
      argResults?['apply-target-platform'] as bool? ?? true;
  final targetPlatformRaw =
      (argResults?['target-platform'] as String? ??
              'android-arm,android-arm64,android-x64')
          .trim();

  final tokens = argResults?.rest ?? <String>[];

  final platformSelections = <BuildPlatform>{};
  final modeSelections = <BuildMode>{};
  final flavorSelections = <BuildFlavor>{};

  for (final token in tokens) {
    final normalized = token.toLowerCase();
    final platform = parsePlatform(normalized);
    if (platform != null) {
      platformSelections.add(platform);
      continue;
    }
    final mode = parseMode(normalized);
    if (mode != null) {
      modeSelections.add(mode);
      continue;
    }
    final flavor = parseFlavor(normalized);
    if (flavor != null) {
      flavorSelections.add(flavor);
      continue;
    }
    throw CommandError(
      'Unrecognized argument "$token". Supported values: android, ios, debug, release, dev, prod.',
      exitCode: 64,
    );
  }

  final hasArtifactFilter =
      requestAndroidAab || requestAndroidApk || requestIosIpa || requestIosApp;

  if (platformSelections.isEmpty) {
    final requestedPlatforms = <BuildPlatform>{};
    if (requestAndroidAab || requestAndroidApk) {
      requestedPlatforms.add(BuildPlatform.android);
    }
    if (requestIosIpa || requestIosApp) {
      requestedPlatforms.add(BuildPlatform.ios);
    }

    if (requestedPlatforms.isNotEmpty) {
      platformSelections.addAll(requestedPlatforms);
    } else {
      platformSelections.addAll(BuildPlatform.values);
    }
  }
  if (modeSelections.isEmpty) {
    if (hasArtifactFilter) {
      modeSelections.add(BuildMode.debug);
    } else {
      modeSelections.addAll(BuildMode.values);
    }
  }
  if (flavorSelections.isEmpty) {
    flavorSelections.addAll(BuildFlavor.values);
  }

  final splitDebugInfoPath = splitDebugInfo && splitDebugInfoPathRaw.isEmpty
      ? './android/app/release'
      : splitDebugInfoPathRaw;
  final targetPlatform = targetPlatformRaw.isEmpty
      ? 'android-arm,android-arm64,android-x64'
      : targetPlatformRaw;

  return BuildCommandOptions(
    keepKeyProperties: keepKeyProperties,
    requestAndroidAab: requestAndroidAab,
    requestAndroidApk: requestAndroidApk,
    requestIosIpa: requestIosIpa,
    requestIosApp: requestIosApp,
    obfuscateAndroid: obfuscateAndroid,
    splitDebugInfo: splitDebugInfo,
    splitDebugInfoPath: splitDebugInfoPath,
    applyTargetPlatform: applyTargetPlatform,
    targetPlatform: targetPlatform,
    platforms: platformSelections,
    modes: modeSelections,
    flavors: flavorSelections,
  );
}
