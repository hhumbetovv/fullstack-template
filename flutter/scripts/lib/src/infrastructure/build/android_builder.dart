import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/domain/models/build_spec.dart';
import 'package:scripts/src/infrastructure/build/artifact_store.dart';
import 'package:scripts/src/infrastructure/build/process_runner.dart';

class AndroidCliOptions {
  const AndroidCliOptions({
    required this.buildAppBundle,
    required this.buildApk,
    required this.obfuscate,
    required this.splitDebugInfo,
    required this.splitDebugInfoPath,
    required this.applyTargetPlatform,
    required this.targetPlatform,
  });

  final bool buildAppBundle;
  final bool buildApk;
  final bool obfuscate;
  final bool splitDebugInfo;
  final String splitDebugInfoPath;
  final bool applyTargetPlatform;
  final String targetPlatform;

  bool shouldBuildFor(BuildSpec spec) {
    if (!buildApk && !buildAppBundle) {
      return false;
    }
    if (spec.mode == BuildMode.debug) {
      return buildApk;
    }
    return buildApk || buildAppBundle;
  }
}

class AndroidBuildService {
  const AndroidBuildService();

  Future<void> build(
    Directory appDir,
    BuildSpec spec,
    AndroidCliOptions options,
    Directory artifactsRoot,
    Set<String> allFlavors,
  ) async {
    if (!options.shouldBuildFor(spec)) {
      return;
    }

    String? version;
    String ensureVersion() => version ??= readAppVersion(appDir);

    if (options.buildApk) {
      await _runFlutterBuild(
        appDir,
        spec,
        options,
        command: 'apk',
      );
      _copyApkArtifacts(
        appDir,
        spec,
        artifactsRoot,
        ensureVersion(),
        allFlavors,
      );
    }

    if (options.buildAppBundle) {
      if (spec.mode != BuildMode.release) {
        Console.warning(
          'Skipping Android App Bundle for ${spec.description} (only release builds supported).',
        );
      } else {
        await _runFlutterBuild(
          appDir,
          spec,
          options,
          command: 'appbundle',
        );
        _copyAppBundleArtifacts(
          appDir,
          spec,
          artifactsRoot,
          ensureVersion(),
          allFlavors,
        );
      }
    }
  }

  Future<void> _runFlutterBuild(
    Directory appDir,
    BuildSpec spec,
    AndroidCliOptions options, {
    required String command,
  }) async {
    final args = <String>[
      'fvm',
      'flutter',
      'build',
      command,
      '--flavor',
      spec.flavor,
      '--dart-define',
      'FLAVOR=${spec.flavor}',
      if (spec.mode == BuildMode.release) '--release' else '--debug',
    ];

    if (command == 'apk' && options.applyTargetPlatform) {
      args
        ..add('--target-platform')
        ..add(options.targetPlatform);
    }

    if (spec.mode == BuildMode.release) {
      if (options.obfuscate) {
        args.add('--obfuscate');
      }
      if (options.splitDebugInfo) {
        args
          ..add('--split-debug-info')
          ..add(options.splitDebugInfoPath);
      }
    }

    await runProcess(
      args,
      workingDirectory: appDir.path,
    );
  }

  void _copyApkArtifacts(
    Directory appDir,
    BuildSpec spec,
    Directory artifactsRoot,
    String version,
    Set<String> allFlavors,
  ) {
    final outputDir = Directory('${appDir.path}/build/app/outputs/flutter-apk');
    if (!outputDir.existsSync()) {
      throw CommandError(
        'Android APK output not found at ${outputDir.path}',
        exitCode: 1,
      );
    }

    final artifacts = outputDir
        .listSync()
        .whereType<File>()
        .where(
          (file) =>
              _matchesAndroidArtifact(file.path, spec, '.apk', allFlavors),
        )
        .toList();

    if (artifacts.isEmpty) {
      throw CommandError(
        'No APK artifacts produced for ${spec.description}.',
        exitCode: 1,
      );
    }

    for (final artifact in artifacts) {
      storeFileArtifact(artifact, artifactsRoot, spec, version);
    }
  }

  void _copyAppBundleArtifacts(
    Directory appDir,
    BuildSpec spec,
    Directory artifactsRoot,
    String version,
    Set<String> allFlavors,
  ) {
    final modeLabel = spec.mode == BuildMode.release ? 'Release' : 'Debug';
    final bundleDir = Directory(
      '${appDir.path}/build/app/outputs/bundle/${spec.flavor}$modeLabel',
    );

    if (!bundleDir.existsSync()) {
      throw CommandError(
        'Android App Bundle output not found at ${bundleDir.path}',
        exitCode: 1,
      );
    }

    final artifacts = bundleDir
        .listSync()
        .whereType<File>()
        .where(
          (file) =>
              _matchesAndroidArtifact(file.path, spec, '.aab', allFlavors),
        )
        .toList();

    if (artifacts.isEmpty) {
      throw CommandError(
        'No App Bundle artifacts produced for ${spec.description}.',
        exitCode: 1,
      );
    }

    for (final artifact in artifacts) {
      storeFileArtifact(artifact, artifactsRoot, spec, version);
    }
  }

  bool _matchesAndroidArtifact(
    String path,
    BuildSpec spec,
    String extension,
    Set<String> allFlavors,
  ) {
    final lower = p.basename(path).toLowerCase();
    if (!lower.endsWith(extension)) {
      return false;
    }

    final flavorToken = '-${spec.flavor.toLowerCase()}-';
    final modeToken = '-${spec.mode.name.toLowerCase()}';

    if (lower.contains(flavorToken)) {
      return lower.contains(modeToken);
    }

    final conflictingTokens = allFlavors
        .where((flavor) => flavor.toLowerCase() != spec.flavor.toLowerCase())
        .map((flavor) => '-${flavor.toLowerCase()}-')
        .where(lower.contains)
        .toList();

    if (conflictingTokens.isEmpty && lower.contains(modeToken)) {
      return true;
    }

    return false;
  }
}
