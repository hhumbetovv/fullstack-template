import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/features/build_engine/features/codegen/adapters/build/artifact_store.dart';
import 'package:scripts/src/features/build_engine/features/codegen/adapters/build/process_runner.dart';
import 'package:scripts/src/features/build_engine/features/codegen/domain/models/build_spec.dart';

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
      '--dart-define',
      'FLAVOR=${spec.flavor}',
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

    final needsBundleLookup =
        options.copyAppBundle ||
        (spec.mode == BuildMode.release && options.copyIpa);

    Directory? bundle;
    if (needsBundleLookup) {
      final bundleRoot = spec.mode == BuildMode.release
          ? Directory('${outputDir.path}/iphoneos')
          : Directory('${outputDir.path}/iphonesimulator');
      bundle = _findAppBundle(bundleRoot, spec.flavor);
      if (bundle == null) {
        Console.warning('No iOS .app bundle found for ${spec.description}.');
      }
    }

    if (options.copyAppBundle && bundle != null) {
      storeDirectoryArtifact(bundle, artifactsRoot, spec, version);
    }

    if (options.copyIpa) {
      if (spec.mode != BuildMode.release) {
        Console.warning(
          'Skipping IPA for ${spec.description} (only release builds supported).',
        );
      } else if (bundle != null) {
        final archive = await _createUnsignedIpa(
          bundle,
          Directory('${outputDir.path}/ipa'),
          spec.flavor,
        );
        storeFileArtifact(archive, artifactsRoot, spec, version);
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

  Future<File> _createUnsignedIpa(
    Directory bundle,
    Directory ipaDir,
    String flavor,
  ) async {
    ipaDir.createSync(recursive: true);
    final ipaFile = File(p.join(ipaDir.path, '$flavor.ipa'));
    if (ipaFile.existsSync()) {
      ipaFile.deleteSync();
    }

    final tempRoot = Directory.systemTemp.createTempSync('ipa-build-');
    try {
      final payloadDir = Directory(p.join(tempRoot.path, 'Payload'))
        ..createSync(recursive: true);
      final bundleCopy = Directory(
        p.join(payloadDir.path, p.basename(bundle.path)),
      );
      _copyDirectorySync(bundle, bundleCopy);
      await runProcess(
        ['zip', '-qry', ipaFile.path, 'Payload'],
        workingDirectory: tempRoot.path,
      );
      return ipaFile;
    } finally {
      if (tempRoot.existsSync()) {
        tempRoot.deleteSync(recursive: true);
      }
    }
  }

  void _copyDirectorySync(Directory source, Directory destination) {
    if (!destination.existsSync()) {
      destination.createSync(recursive: true);
    }

    for (final entity in source.listSync(followLinks: false)) {
      final newPath = p.join(destination.path, p.basename(entity.path));
      if (entity is File) {
        File(newPath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(entity.readAsBytesSync());
      } else if (entity is Directory) {
        _copyDirectorySync(entity, Directory(newPath));
      }
    }
  }
}
