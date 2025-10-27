import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import '../../core/core.dart';

enum BuildPlatform { android, ios }

enum BuildMode { debug, release }

enum BuildFlavor { dev, prod }

class _BuildSpec {
  const _BuildSpec({
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

class _AndroidCliOptions {
  const _AndroidCliOptions({
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

/// Entry point invoked by the build command.
Future<int> runBuildFeature(ArgResults? argResults) async {
  final keepKeyProperties =
      argResults?['keep-key-properties'] as bool? ?? false;
  final requestAndroidAab = argResults?['android-aab'] as bool? ?? false;
  final requestAndroidApk = argResults?['android-apk'] as bool? ?? false;
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
    final platform = _parsePlatform(normalized);
    if (platform != null) {
      platformSelections.add(platform);
      continue;
    }
    final mode = _parseMode(normalized);
    if (mode != null) {
      modeSelections.add(mode);
      continue;
    }
    final flavor = _parseFlavor(normalized);
    if (flavor != null) {
      flavorSelections.add(flavor);
      continue;
    }
    throw CommandError(
      'Unrecognized argument "$token". Supported values: android, ios, debug, release, dev, prod.',
      exitCode: 64,
    );
  }

  if (platformSelections.isEmpty) {
    platformSelections.addAll(BuildPlatform.values);
  }
  if (modeSelections.isEmpty) {
    modeSelections.addAll(BuildMode.values);
  }
  if (flavorSelections.isEmpty) {
    flavorSelections.addAll(BuildFlavor.values);
  }

  final specs = <_BuildSpec>[
    for (final platform in platformSelections)
      for (final mode in modeSelections)
        for (final flavor in flavorSelections)
          _BuildSpec(
            platform: platform,
            mode: mode,
            flavor: flavor,
          ),
  ]..sort(_compareSpecs);

  if (specs.isEmpty) {
    Console.warning('No build targets selected.');
    return 0;
  }

  final needsAndroidKeystore = specs.any(
    (spec) =>
        spec.platform == BuildPlatform.android &&
        spec.mode == BuildMode.release,
  );

  final splitDebugInfoPath = splitDebugInfo && splitDebugInfoPathRaw.isEmpty
      ? './android/app/release'
      : splitDebugInfoPathRaw;
  final targetPlatform = targetPlatformRaw.isEmpty
      ? 'android-arm,android-arm64,android-x64'
      : targetPlatformRaw;

  final androidCliOptions = _AndroidCliOptions(
    requestAppBundle: requestAndroidAab,
    requestApk: requestAndroidApk,
    obfuscate: obfuscateAndroid,
    splitDebugInfo: splitDebugInfo,
    splitDebugInfoPath: splitDebugInfoPath,
    applyTargetPlatform: applyTargetPlatform,
    targetPlatform: targetPlatform,
  );
  final repoRoot = Directory.current;
  final appDir = Directory('${repoRoot.path}/app');
  if (!appDir.existsSync()) {
    throw const CommandError(
      'Could not locate the app directory at ./app. Run from repository root.',
      exitCode: 66,
    );
  }

  final keyPropertiesFile = File('${appDir.path}/android/key.properties');
  final hadExistingKeyProperties = keyPropertiesFile.existsSync();

  String? normalizedEnv(String key) {
    final value = Platform.environment[key];
    return (value == null || value.trim().isEmpty) ? null : value.trim();
  }

  String? resolveKeystorePath() {
    final directPath = normalizedEnv('ANDROID_KEYSTORE_PATH');
    if (directPath != null && directPath.isNotEmpty) {
      return directPath;
    }
    final relativePath = File('android/key.properties');
    if (relativePath.existsSync()) {
      return relativePath.path;
    }
    return null;
  }

  String? keystorePath;
  String? keystorePassword;
  String? keyAlias;
  String? keyPassword;

  if (needsAndroidKeystore) {
    keystorePath = resolveKeystorePath();
    keystorePassword = normalizedEnv('ANDROID_KEYSTORE_PASSWORD');
    keyAlias = normalizedEnv('ANDROID_KEY_ALIAS');
    keyPassword = normalizedEnv('ANDROID_KEY_PASSWORD');

    if ([
      keystorePath,
      keystorePassword,
      keyAlias,
      keyPassword,
    ].any((value) => value == null)) {
      throw const CommandError(
        'Android release builds require ANDROID_KEYSTORE_PATH, '
        'ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD.',
        exitCode: 64,
      );
    }

    _writeKeyProperties(
      keyPropertiesFile,
      keystorePath!,
      keystorePassword!,
      keyAlias!,
      keyPassword!,
    );
  }

  final artifactsRoot = Directory('ignores/artifacts');
  if (!artifactsRoot.existsSync()) {
    artifactsRoot.createSync(recursive: true);
  }

  final failures = <String>[];

  try {
    for (final spec in specs) {
      Console.info('\n🔨 Building ${spec.description}');
      try {
        if (spec.platform == BuildPlatform.android) {
          await _buildAndroidTarget(
            appDir,
            spec,
            androidCliOptions,
            artifactsRoot,
          );
        } else {
          await _buildIosTarget(appDir, spec, artifactsRoot);
        }
      } on CommandError catch (error) {
        failures.add(spec.description);
        Console.error('Build failed for ${spec.description}: ${error.message}');
      }
    }
  } finally {
    if (!keepKeyProperties &&
        !hadExistingKeyProperties &&
        keyPropertiesFile.existsSync()) {
      keyPropertiesFile.deleteSync();
    }
  }

  if (failures.isNotEmpty) {
    Console.error('\n❌ Failures encountered for: ${failures.join(', ')}');
    return 1;
  }

  Console.success('\n🎉 Build matrix completed successfully!');
  return 0;
}

Future<void> _buildAndroidTarget(
  Directory appDir,
  _BuildSpec spec,
  _AndroidCliOptions options,
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

  await _runProcess(buildArgs);

  final version = _readAppVersion(appDir);
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
    _storeFileArtifact(artifact, artifactsRoot, spec, version);
  }
}

Future<void> _buildIosTarget(
  Directory appDir,
  _BuildSpec spec,
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

  await _runProcess(args);

  final version = _readAppVersion(appDir);
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
    _storeDirectoryArtifact(bundle, artifactsRoot, spec, version);
  }

  final archive = File('${outputDir.path}/ipa/${spec.flavor.name}.ipa');
  if (archive.existsSync()) {
    _storeFileArtifact(archive, artifactsRoot, spec, version);
  }
}

Future<void> _runProcess(List<String> args) async {
  final process = await Process.start(
    args.first,
    args.sublist(1),
    mode: ProcessStartMode.inheritStdio,
  );
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw CommandError('Command failed: ${args.join(' ')}', exitCode: exitCode);
  }
}

String _readAppVersion(Directory appDir) {
  final pubspec = File('${appDir.path}/pubspec.yaml');
  if (!pubspec.existsSync()) {
    throw CommandError('app/pubspec.yaml not found', exitCode: 66);
  }
  final lines = pubspec.readAsLinesSync();
  for (final line in lines) {
    if (line.trim().startsWith('version:')) {
      return line.split(':')[1].trim();
    }
  }
  return '0.0.0';
}

void _storeFileArtifact(
  File source,
  Directory artifactsRoot,
  _BuildSpec spec,
  String version,
) {
  final destinationDir = Directory(
    p.join(
      artifactsRoot.path,
      spec.platform.name,
      spec.mode.name,
      spec.flavor.name,
    ),
  )..createSync(recursive: true);

  final extension = p.extension(source.path);
  final destName =
      '${spec.platform.name}-${spec.mode.name}-${spec.flavor.name}-v$version$extension';
  final destination = File(p.join(destinationDir.path, destName));
  if (destination.existsSync()) {
    destination.deleteSync();
  }
  source.copySync(destination.path);
}

Directory _storeDirectoryArtifact(
  Directory source,
  Directory artifactsRoot,
  _BuildSpec spec,
  String version,
) {
  final destinationDir = Directory(
    p.join(
      artifactsRoot.path,
      spec.platform.name,
      spec.mode.name,
      spec.flavor.name,
    ),
  )..createSync(recursive: true);

  final originalName = p.basename(source.path);
  final destName = '$originalName-v$version';
  final destination = Directory(p.join(destinationDir.path, destName));
  if (destination.existsSync()) {
    destination.deleteSync(recursive: true);
  }

  _copyDirectorySync(source, destination);
  return destination;
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

void _writeKeyProperties(
  File file,
  String storeFilePath,
  String storePassword,
  String keyAlias,
  String keyPassword,
) {
  file
    ..createSync(recursive: true)
    ..writeAsStringSync(
      'storeFile=${_escapePropertyValue(storeFilePath)}\n'
      'storePassword=${_escapePropertyValue(storePassword)}\n'
      'keyAlias=${_escapePropertyValue(keyAlias)}\n'
      'keyPassword=${_escapePropertyValue(keyPassword)}\n',
    );
  try {
    Process.runSync('chmod', ['600', file.path]);
  } on ProcessException {
    // Ignore platforms without chmod.
  }
}

String _escapePropertyValue(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r')
      .replaceAll('\t', r'\t')
      .replaceAll('#', r'\#')
      .replaceAll('=', r'\=')
      .replaceAll(':', r'\:')
      .replaceAll(' ', r'\ ');
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

BuildPlatform? _parsePlatform(String value) {
  switch (value) {
    case 'android':
      return BuildPlatform.android;
    case 'ios':
      return BuildPlatform.ios;
  }
  return null;
}

BuildMode? _parseMode(String value) {
  switch (value) {
    case 'debug':
      return BuildMode.debug;
    case 'release':
      return BuildMode.release;
  }
  return null;
}

BuildFlavor? _parseFlavor(String value) {
  switch (value) {
    case 'dev':
      return BuildFlavor.dev;
    case 'prod':
      return BuildFlavor.prod;
  }
  return null;
}

int _compareSpecs(_BuildSpec a, _BuildSpec b) {
  final platformCompare = a.platform.index.compareTo(b.platform.index);
  if (platformCompare != 0) return platformCompare;
  final modeCompare = a.mode.index.compareTo(b.mode.index);
  if (modeCompare != 0) return modeCompare;
  return a.flavor.index.compareTo(b.flavor.index);
}
