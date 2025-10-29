import 'dart:io';

import 'package:args/args.dart';

import '../../core/core.dart';
import 'command/options.dart';
import 'models/build_spec.dart';
import 'services/android_builder.dart';
import 'services/ios_builder.dart';
import 'services/keystore_manager.dart';

Future<int> runBuildFeature(ArgResults? argResults) async {
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

  final artifactsRoot = Directory('ignores/artifacts');
  if (!artifactsRoot.existsSync()) {
    artifactsRoot.createSync(recursive: true);
  }

  final androidCliOptions = AndroidCliOptions(
    requestAppBundle: options.requestAndroidAab,
    requestApk: options.requestAndroidApk,
    obfuscate: options.obfuscateAndroid,
    splitDebugInfo: options.splitDebugInfo,
    splitDebugInfoPath: options.splitDebugInfoPath,
    applyTargetPlatform: options.applyTargetPlatform,
    targetPlatform: options.targetPlatform,
  );

  final keystoreState = prepareAndroidKeystore(appDir, needsAndroidKeystore);

  final failures = <String>[];

  try {
    for (final spec in specs) {
      Console.info('\n🔨 Building ${spec.description}');
      try {
        if (spec.platform == BuildPlatform.android) {
          await buildAndroidTarget(
            appDir,
            spec,
            androidCliOptions,
            artifactsRoot,
          );
        } else {
          await buildIosTarget(appDir, spec, artifactsRoot);
        }
      } on CommandError catch (error) {
        failures.add(spec.description);
        Console.error('Build failed for ${spec.description}: ${error.message}');
      }
    }
  } finally {
    cleanupAndroidKeystore(keystoreState, options.keepKeyProperties);
  }

  if (failures.isNotEmpty) {
    Console.error('\n❌ Failures encountered for: ${failures.join(', ')}');
    return 1;
  }

  Console.success('\n🎉 Build matrix completed successfully!');
  return 0;
}
