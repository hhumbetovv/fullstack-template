import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scripts/src/core/core.dart';

import '../models/build_spec.dart';
import 'artifact_store.dart';
import 'process_runner.dart';

class AndroidCliOptions {
  const AndroidCliOptions({
    required this.requestAppBundle,
    required this.requestApk,
    required this.obfuscate,
    required this.splitDebugInfo,
    required this.splitDebugInfoPath,
    required this.applyTargetPlatform,
    required this.targetPlatform,
  });

  final bool requestAppBundle;
  final bool requestApk;
  final bool obfuscate;
  final bool splitDebugInfo;
  final String splitDebugInfoPath;
  final bool applyTargetPlatform;
  final String targetPlatform;
}

Future<void> buildAndroidTarget(
  Directory appDir,
  BuildSpec spec,
  AndroidCliOptions options,
  Directory artifactsRoot,
) async {
  final buildArgs = <String>[
    'fvm',
    'flutter',
    'build',
    'apk',
    '--flavor',
    spec.flavor.name,
    if (spec.mode == BuildMode.release) '--release' else '--debug',
  ];

  if (options.applyTargetPlatform) {
    buildArgs
      ..add('--target-platform')
      ..add(options.targetPlatform);
  }

  if (spec.mode == BuildMode.release) {
    if (options.obfuscate) {
      buildArgs.add('--obfuscate');
    }
    if (options.splitDebugInfo) {
      buildArgs
        ..add('--split-debug-info')
        ..add(options.splitDebugInfoPath);
    }
  }

  await runProcess(buildArgs);

  final version = readAppVersion(appDir);
  final buildOutputDir = Directory(
    '${appDir.path}/build/app/outputs/flutter-apk',
  );

  if (!buildOutputDir.existsSync()) {
    throw CommandError(
      'Android build output not found at ${buildOutputDir.path}',
      exitCode: 1,
    );
  }

  final artifacts = buildOutputDir.listSync().whereType<File>().where((file) {
    final lower = p.basename(file.path).toLowerCase();
    if (spec.mode == BuildMode.debug) {
      return lower.endsWith('-${spec.flavor.name}-debug.apk');
    }
    if (options.requestAppBundle) {
      return lower.endsWith('.aab') ||
          lower.endsWith('-${spec.flavor.name}-release.apk');
    }
    return lower.endsWith('-${spec.flavor.name}-release.apk');
  });

  for (final artifact in artifacts) {
    storeFileArtifact(artifact, artifactsRoot, spec, version);
  }
}
