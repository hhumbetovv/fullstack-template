import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/domain/models/build_spec.dart';
import 'package:scripts/src/infrastructure/build/artifact_store.dart';
import 'package:scripts/src/infrastructure/build/process_runner.dart';

class IosBuildOptions {
  const IosBuildOptions({
    required this.copyIpa,
    required this.copyAppBundle,
  });

  final bool copyIpa;
  final bool copyAppBundle;

  bool shouldBuildFor(BuildSpec spec) {
    if (!copyIpa && !copyAppBundle) {
      return false;
    }
    if (spec.mode == BuildMode.debug) {
      return copyAppBundle;
    }
    return copyAppBundle || copyIpa;
  }
}

class IosBuildService {
  const IosBuildService();

  Future<void> build(
    Directory appDir,
    BuildSpec spec,
    Directory artifactsRoot,
    IosBuildOptions options,
  ) async {
    if (!options.shouldBuildFor(spec)) {
      return;
    }

    final args = <String>[
      'fvm',
      'flutter',
      'build',
      'ios',
      '--flavor',
      spec.flavor,
      if (spec.mode == BuildMode.release) '--release' else '--debug',
    ];

    if (spec.mode == BuildMode.debug) {
      args.add('--simulator');
    } else {
      args.add('--no-codesign');
    }

    await runProcess(
      args,
      workingDirectory: appDir.path,
    );

    final version = readAppVersion(appDir);
    final outputDir = Directory('${appDir.path}/build/ios');

    if (!outputDir.existsSync()) {
      throw CommandError(
        'iOS build output not found at ${outputDir.path}',
        exitCode: 1,
      );
    }

    if (options.copyAppBundle) {
      final bundleRoot = spec.mode == BuildMode.release
          ? Directory('${outputDir.path}/iphoneos')
          : Directory('${outputDir.path}/iphonesimulator');
      final bundle = _findAppBundle(bundleRoot, spec.flavor);
      if (bundle != null) {
        storeDirectoryArtifact(bundle, artifactsRoot, spec, version);
      } else {
        Console.warning('No iOS .app bundle found for ${spec.description}.');
      }
    }

    if (options.copyIpa) {
      if (spec.mode != BuildMode.release) {
        Console.warning(
          'Skipping IPA for ${spec.description} (only release builds supported).',
        );
      } else {
        final archive = File('${outputDir.path}/ipa/${spec.flavor}.ipa');
        if (archive.existsSync()) {
          storeFileArtifact(archive, artifactsRoot, spec, version);
        } else {
          Console.warning('No IPA artifact found for ${spec.description}.');
        }
      }
    }
  }

  Directory? _findAppBundle(Directory parent, String flavor) {
    if (!parent.existsSync()) {
      return null;
    }

    Directory? fallback;
    final entries = parent.listSync().whereType<Directory>();
    for (final entry in entries) {
      final name = p.basename(entry.path).toLowerCase();
      if (!name.endsWith('.app')) {
        continue;
      }
      if (name == 'runner-${flavor.toLowerCase()}.app') {
        return entry;
      }
      fallback ??= entry;
    }
    return fallback;
  }
}
