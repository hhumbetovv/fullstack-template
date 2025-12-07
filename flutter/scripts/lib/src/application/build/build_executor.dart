import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:scripts/src/cli/build/options.dart';
import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/domain/models/build_spec.dart';
import 'package:scripts/src/infrastructure/build/android_builder.dart';
import 'package:scripts/src/infrastructure/build/ios_builder.dart';
import 'package:scripts/src/infrastructure/build/keystore_manager.dart';

class BuildExecutor {
  BuildExecutor({
    required AndroidBuildService androidBuildService,
    required IosBuildService iosBuildService,
    required AndroidKeystoreManager keystoreManager,
  }) : _androidBuildService = androidBuildService,
       _iosBuildService = iosBuildService,
       _keystoreManager = keystoreManager;

  final AndroidBuildService _androidBuildService;
  final IosBuildService _iosBuildService;
  final AndroidKeystoreManager _keystoreManager;

  Future<int> run(ArgResults? argResults) async {
    final options = parseBuildCommandArgs(argResults);
    final repoRoot = Directory.current;
    final appDir = Directory('${repoRoot.path}/app');
    if (!appDir.existsSync()) {
      throw const CommandError(
        'Could not locate the app directory at ./app. Run from repository root.',
        exitCode: 66,
      );
    }

    final discoveredFlavors = _discoverFlavors(appDir);
    final selectedFlavors = _resolveFlavors(
      requestedFlavors: options.requestedFlavors,
      discoveredFlavors: discoveredFlavors,
    );

    final specs = createBuildSpecs(
      options.platforms,
      options.modes,
      selectedFlavors,
    );

    final needsIosReleaseBuilds =
        options.requestIosIpa &&
        options.platforms.contains(BuildPlatform.ios) &&
        !specs.any(
          (spec) =>
              spec.platform == BuildPlatform.ios &&
              spec.mode == BuildMode.release,
        );

    if (needsIosReleaseBuilds) {
      Console.warning(
        'IPA artifacts require iOS release builds. Adding release mode to the build matrix.',
      );
      for (final flavor in selectedFlavors) {
        specs.add(
          BuildSpec(
            platform: BuildPlatform.ios,
            mode: BuildMode.release,
            flavor: flavor,
          ),
        );
      }
      specs.sort(compareBuildSpecs);
    }

    if (specs.isEmpty) {
      Console.warning('No build targets selected.');
      return 0;
    }

    final needsAndroidKeystore = specs.any(
      (spec) =>
          spec.platform == BuildPlatform.android &&
          spec.mode == BuildMode.release,
    );

    final artifactsRoot = Directory('.misc/artifacts');
    if (!artifactsRoot.existsSync()) {
      artifactsRoot.createSync(recursive: true);
    }

    final androidCliOptions = AndroidCliOptions(
      buildAppBundle: options.requestAndroidAab,
      buildApk: options.requestAndroidApk || !options.requestAndroidAab,
      obfuscate: options.obfuscateAndroid,
      splitDebugInfo: options.splitDebugInfo,
      splitDebugInfoPath: options.splitDebugInfoPath,
      applyTargetPlatform: options.applyTargetPlatform,
      targetPlatform: options.targetPlatform,
    );

    final iosCliOptions = IosBuildOptions(
      copyIpa:
          options.requestIosIpa ||
          (!options.requestIosIpa && !options.requestIosApp),
      copyAppBundle:
          options.requestIosApp ||
          (!options.requestIosIpa && !options.requestIosApp),
    );

    final keystoreState = _keystoreManager.prepare(
      appDir,
      needsAndroidKeystore,
    );

    final failures = <String>[];

    try {
      for (final spec in specs) {
        Console.info('\n🔨 Building ${spec.description}');
        try {
          if (spec.platform == BuildPlatform.android) {
            await _androidBuildService.build(
              appDir,
              spec,
              androidCliOptions,
              artifactsRoot,
              selectedFlavors,
            );
          } else {
            await _iosBuildService.build(
              appDir,
              spec,
              artifactsRoot,
              iosCliOptions,
            );
          }
        } on CommandError catch (error) {
          failures.add(spec.description);
          Console.error(
            'Build failed for ${spec.description}: ${error.message}',
          );
        }
      }
    } finally {
      _keystoreManager.cleanup(keystoreState, options.keepKeyProperties);
    }

    if (failures.isNotEmpty) {
      Console.error('\n❌ Failures encountered for: ${failures.join(', ')}');
      return 1;
    }

    Console.success('\n🎉 Build matrix completed successfully!');
    return 0;
  }

  Set<String> _discoverFlavors(Directory appDir) {
    final entries = appDir
        .listSync(followLinks: false)
        .whereType<File>()
        .map((file) => p.basename(file.path));

    final flavors = <String>{};
    for (final name in entries) {
      final flavor = _deriveFlavorName(name);
      if (flavor != null && flavor.isNotEmpty) {
        flavors.add(flavor);
      }
    }

    if (flavors.isEmpty) {
      throw const CommandError(
        'Could not infer build flavors. Add .env.{flavor} or {flavor}.env files under ./app.',
        exitCode: 66,
      );
    }

    return flavors;
  }

  Set<String> _resolveFlavors({
    required Set<String> requestedFlavors,
    required Set<String> discoveredFlavors,
  }) {
    final normalizedAvailable = <String, String>{
      for (final flavor in discoveredFlavors) flavor.toLowerCase(): flavor,
    };

    if (requestedFlavors.isEmpty) {
      return normalizedAvailable.values.toSet();
    }

    final resolved = <String>{};
    final missing = <String>[];
    for (final requested in requestedFlavors) {
      final normalized = requested.toLowerCase();
      final match = normalizedAvailable[normalized];
      if (match == null) {
        missing.add(requested);
      } else {
        resolved.add(match);
      }
    }

    if (missing.isNotEmpty) {
      final availableList = normalizedAvailable.values.toList()..sort();
      throw CommandError(
        'Unknown flavor(s): ${missing.join(', ')}. Available: ${availableList.join(', ')}.',
        exitCode: 64,
      );
    }

    return resolved;
  }

  String? _deriveFlavorName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower == '.env') {
      return null;
    }
    if (lower.startsWith('.env.')) {
      final suffix = lower.substring(5);
      return suffix.split('.').first;
    }
    if (lower.endsWith('.env')) {
      final prefix = lower.substring(0, lower.length - 4);
      return prefix
          .split('.')
          .lastWhere(
            (segment) => segment.isNotEmpty,
            orElse: () => '',
          );
    }
    return null;
  }
}
