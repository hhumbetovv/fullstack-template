import 'dart:io';

import 'package:args/args.dart';
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
    final specs = createBuildSpecs(
      options.platforms,
      options.modes,
      options.flavors,
    );

    if (specs.isEmpty) {
      Console.warning('No build targets selected.');
      return 0;
    }

    final needsAndroidKeystore = specs.any(
      (spec) =>
          spec.platform == BuildPlatform.android &&
          spec.mode == BuildMode.release,
    );

    final repoRoot = Directory.current;
    final appDir = Directory('${repoRoot.path}/app');
    if (!appDir.existsSync()) {
      throw const CommandError(
        'Could not locate the app directory at ./app. Run from repository root.',
        exitCode: 66,
      );
    }

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
}
