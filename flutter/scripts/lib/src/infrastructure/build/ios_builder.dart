import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/domain/models/build_spec.dart';
import 'package:scripts/src/infrastructure/build/artifact_store.dart';
import 'package:scripts/src/infrastructure/build/process_runner.dart';

class IosBuildService {
  const IosBuildService();

  Future<void> build(
    Directory appDir,
    BuildSpec spec,
    Directory artifactsRoot,
  ) async {
    final args = <String>[
      'fvm',
      'flutter',
      'build',
      'ios',
      '--flavor',
      spec.flavor.name,
      if (spec.mode == BuildMode.release) '--release' else '--debug',
    ];

    if (spec.mode == BuildMode.debug) {
      args.add('--simulator');
    } else {
      args.add('--no-codesign');
    }

    await runProcess(args);

    final version = readAppVersion(appDir);
    final outputDir = Directory('${appDir.path}/build/ios');

    if (!outputDir.existsSync()) {
      throw CommandError(
        'iOS build output not found at ${outputDir.path}',
        exitCode: 1,
      );
    }

    final bundle = _findAppBundle(
      Directory('${outputDir.path}/iphoneos'),
      spec.flavor.name,
    );
    if (bundle != null) {
      storeDirectoryArtifact(bundle, artifactsRoot, spec, version);
    }

    final archive = File('${outputDir.path}/ipa/${spec.flavor.name}.ipa');
    if (archive.existsSync()) {
      storeFileArtifact(archive, artifactsRoot, spec, version);
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
      if (name == 'runner-$flavor.app') {
        return entry;
      }
      fallback ??= entry;
    }
    return fallback;
  }
}
