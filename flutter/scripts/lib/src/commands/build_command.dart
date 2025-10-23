import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:scripts/src/common/console.dart';
import 'package:scripts/src/core/errors.dart';

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

  String get description => '${platform.name} ${mode.name} ${flavor.name}'.toUpperCase();
}

enum _AndroidArtifact { appBundle, releaseApk, debugApk }

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

class BuildCommand extends Command<int> {
  BuildCommand() {
    argParser
      ..addFlag(
        'keep-key-properties',
        help: 'Keep the generated android/key.properties file after the build.',
        negatable: false,
      )
      ..addFlag(
        'android-aab',
        help: 'Only build the Android App Bundle release artifact.',
        negatable: false,
      )
      ..addFlag(
        'android-apk',
        help: 'Only build the Android APK release artifact.',
        negatable: false,
      )
      ..addFlag(
        'obfuscate',
        help: 'Add --obfuscate to Android release builds.',
        defaultsTo: true,
      )
      ..addFlag(
        'split-debug-info',
        help: 'Add --split-debug-info to Android release builds.',
        defaultsTo: true,
      )
      ..addOption(
        'split-debug-info-path',
        help: 'Directory used when --split-debug-info is enabled.',
        valueHelp: 'dir',
        defaultsTo: './android/app/release',
      )
      ..addFlag(
        'apply-target-platform',
        help: 'Add --target-platform for Android builds.',
        defaultsTo: true,
      )
      ..addOption(
        'target-platform',
        help: 'Value used for --target-platform when applied.',
        valueHelp: 'platforms',
        defaultsTo: 'android-arm,android-arm64,android-x64',
      );
  }

  @override
  String get name => 'build';

  @override
  String get description => 'Run bootstrap and produce Android/iOS artifacts across modes and flavors.';

  @override
  Future<int> run() async {
    final keepKeyProperties = argResults?['keep-key-properties'] as bool? ?? false;
    final requestAndroidAab = argResults?['android-aab'] as bool? ?? false;
    final requestAndroidApk = argResults?['android-apk'] as bool? ?? false;
    final obfuscateAndroid = argResults?['obfuscate'] as bool? ?? true;
    final splitDebugInfo = argResults?['split-debug-info'] as bool? ?? true;
    final splitDebugInfoPathRaw = (argResults?['split-debug-info-path'] as String? ?? './android/app/release').trim();
    final applyTargetPlatform = argResults?['apply-target-platform'] as bool? ?? true;
    final targetPlatformRaw = (argResults?['target-platform'] as String? ?? 'android-arm,android-arm64,android-x64')
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
      (spec) => spec.platform == BuildPlatform.android && spec.mode == BuildMode.release,
    );

    final splitDebugInfoPath = splitDebugInfo && splitDebugInfoPathRaw.isEmpty
        ? './android/app/release'
        : splitDebugInfoPathRaw;
    final targetPlatform = targetPlatformRaw.isEmpty ? 'android-arm,android-arm64,android-x64' : targetPlatformRaw;

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
      if (value == null) {
        return null;
      }
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    final keystorePath = normalizedEnv('ANDROID_KEYSTORE_PATH');
    final keystorePassword = normalizedEnv('ANDROID_KEYSTORE_PASSWORD');
    final keyAlias = normalizedEnv('ANDROID_KEY_ALIAS');
    final keyPassword = normalizedEnv('ANDROID_KEY_PASSWORD');

    final envValues = <String, String?>{
      'ANDROID_KEYSTORE_PATH': keystorePath,
      'ANDROID_KEYSTORE_PASSWORD': keystorePassword,
      'ANDROID_KEY_ALIAS': keyAlias,
      'ANDROID_KEY_PASSWORD': keyPassword,
    };

    final hasAllKeystoreEnv = envValues.values.every((value) => value != null);
    final hasAnyKeystoreEnv = envValues.values.any((value) => value != null);

    File? keystoreFile;

    if (needsAndroidKeystore) {
      if (hasAnyKeystoreEnv && !hasAllKeystoreEnv) {
        final missingKeys = envValues.entries.where((entry) => entry.value == null).map((entry) => entry.key).toList();
        throw CommandError(
          'Android release builds require environment variables: ${missingKeys.join(', ')}.',
          exitCode: 64,
        );
      }

      if (hasAllKeystoreEnv) {
        keystoreFile = File(keystorePath!);
        if (!keystoreFile.existsSync()) {
          throw CommandError(
            'Keystore file not found at ${keystoreFile.path}.',
            exitCode: 66,
          );
        }
      } else if (hadExistingKeyProperties) {
        Console.info(
          'Using existing android/key.properties for Android release signing.',
        );
      } else {
        Console.info(
          'No signing environment variables detected; Android release builds will use the debug signing configuration.',
        );
      }
    }

    final appVersion = _readAppVersion(appDir);
    Console.info('Detected app version: $appVersion');

    final artifactsRoot = Directory(
      p.join(repoRoot.path, 'ignores', 'artifacts'),
    );
    if (!artifactsRoot.existsSync()) {
      artifactsRoot.createSync(recursive: true);
    }

    Console.info('Running bootstrap.sh ...');
    await _runProcess(
      ['bash', 'scripts/bash/bootstrap.sh'],
      workingDirectory: repoRoot.path,
      description: 'bootstrap.sh',
    );

    final flutterCommand = await _resolveFlutterCommand();

    var keyPropertiesCreated = false;

    if (needsAndroidKeystore && hasAllKeystoreEnv) {
      Console.info('Preparing Android signing configuration ...');
      _writeKeyProperties(
        keyPropertiesFile,
        keystoreFile!.absolute.path,
        keystorePassword!,
        keyAlias!,
        keyPassword!,
      );
      keyPropertiesCreated = !hadExistingKeyProperties;
    }

    final androidReleaseDir = Directory('${appDir.path}/android/app/release');
    if (needsAndroidKeystore && !androidReleaseDir.existsSync()) {
      androidReleaseDir.createSync(recursive: true);
    }

    try {
      Console.info(
        'Building targets: ${specs.map((s) => s.description).join(', ')}',
      );
      for (final spec in specs) {
        Console.write('\n➡️  Building ${spec.description}');
        if (spec.platform == BuildPlatform.android) {
          await _buildAndroid(
            flutterCommand,
            appDir,
            artifactsRoot,
            spec,
            appVersion,
            androidCliOptions,
          );
        } else {
          await _buildIos(
            flutterCommand,
            appDir,
            artifactsRoot,
            spec,
            appVersion,
          );
        }
      }
    } finally {
      if (keyPropertiesCreated && !hadExistingKeyProperties && !keepKeyProperties) {
        if (keyPropertiesFile.existsSync()) {
          keyPropertiesFile.deleteSync();
        }
      }
    }

    Console.success('\n🎉 Build orchestration completed.');
    return 0;
  }
}

int _compareSpecs(_BuildSpec a, _BuildSpec b) {
  const platformOrder = BuildPlatform.values;
  const modeOrder = [BuildMode.release, BuildMode.debug];
  const flavorOrder = BuildFlavor.values;

  final platformComparison = platformOrder.indexOf(a.platform) - platformOrder.indexOf(b.platform);
  if (platformComparison != 0) {
    return platformComparison;
  }

  final modeComparison = modeOrder.indexOf(a.mode) - modeOrder.indexOf(b.mode);
  if (modeComparison != 0) {
    return modeComparison;
  }

  return flavorOrder.indexOf(a.flavor) - flavorOrder.indexOf(b.flavor);
}

BuildPlatform? _parsePlatform(String value) {
  switch (value) {
    case 'android':
      return BuildPlatform.android;
    case 'ios':
      return BuildPlatform.ios;
    default:
      return null;
  }
}

BuildMode? _parseMode(String value) {
  switch (value) {
    case 'debug':
      return BuildMode.debug;
    case 'release':
      return BuildMode.release;
    default:
      return null;
  }
}

BuildFlavor? _parseFlavor(String value) {
  switch (value) {
    case 'dev':
      return BuildFlavor.dev;
    case 'prod':
      return BuildFlavor.prod;
    default:
      return null;
  }
}

Future<void> _buildAndroid(
  List<String> flutterCommand,
  Directory appDir,
  Directory artifactsRoot,
  _BuildSpec spec,
  String version,
  _AndroidCliOptions options,
) async {
  final flavorName = spec.flavor.name;

  final artifacts = <_AndroidArtifact>[];
  if (spec.mode == BuildMode.release) {
    final hasExplicitSelection = options.requestAppBundle || options.requestApk;
    if (!hasExplicitSelection || options.requestAppBundle) {
      artifacts.add(_AndroidArtifact.appBundle);
    }
    if (!hasExplicitSelection || options.requestApk) {
      artifacts.add(_AndroidArtifact.releaseApk);
    }
  } else {
    artifacts.add(_AndroidArtifact.debugApk);
  }

  if (artifacts.isEmpty) {
    Console.warning(
      'No Android artifacts selected for ${spec.description}, skipping.',
    );
    return;
  }

  for (final artifact in artifacts) {
    final commandTarget = switch (artifact) {
      _AndroidArtifact.appBundle => 'appbundle',
      _AndroidArtifact.releaseApk => 'apk',
      _AndroidArtifact.debugApk => 'apk',
    };

    final buildArgs = <String>[...flutterCommand, 'build', commandTarget];
    final additionalArgs = <String>[
      '--flavor',
      flavorName,
      '--dart-define=FLAVOR=$flavorName',
    ];

    final isReleaseArtifact = artifact != _AndroidArtifact.debugApk;
    if (isReleaseArtifact) {
      final releaseArgs = <String>['--release'];
      if (options.obfuscate) {
        releaseArgs.add('--obfuscate');
      }
      if (options.splitDebugInfo) {
        final dir = options.splitDebugInfoPath.isEmpty ? './android/app/release' : options.splitDebugInfoPath;
        releaseArgs.add('--split-debug-info=$dir');
      }
      additionalArgs.addAll(releaseArgs);
    } else {
      additionalArgs.add('--debug');
    }

    if (options.applyTargetPlatform && options.targetPlatform.isNotEmpty) {
      additionalArgs.addAll(<String>[
        '--target-platform',
        options.targetPlatform,
      ]);
    }

    buildArgs.addAll(additionalArgs);

    final artifactLabel = switch (artifact) {
      _AndroidArtifact.appBundle => 'App Bundle',
      _AndroidArtifact.releaseApk => 'release APK',
      _AndroidArtifact.debugApk => 'debug APK',
    };

    await _runProcess(
      buildArgs,
      workingDirectory: appDir.path,
      description: 'flutter ${commandTarget.toUpperCase()} (${spec.description} $artifactLabel)',
    );

    final outputPath = switch (artifact) {
      _AndroidArtifact.appBundle => p.join(
        appDir.path,
        'build',
        'app',
        'outputs',
        'bundle',
        '${flavorName}Release',
        'app-$flavorName-release.aab',
      ),
      _AndroidArtifact.releaseApk => p.join(
        appDir.path,
        'build',
        'app',
        'outputs',
        'apk',
        flavorName,
        'release',
        'app-$flavorName-release.apk',
      ),
      _AndroidArtifact.debugApk => p.join(
        appDir.path,
        'build',
        'app',
        'outputs',
        'flutter-apk',
        'app-$flavorName-debug.apk',
      ),
    };

    final outputFile = File(outputPath);
    if (!outputFile.existsSync()) {
      throw CommandError(
        'Expected Android artifact not found at ${_relativePath(outputPath)}.',
        exitCode: 65,
      );
    }

    final storedFile = _storeFileArtifact(
      outputFile,
      artifactsRoot,
      spec,
      version,
    );

    Console.success(
      '✅ Android ${spec.mode.name} $flavorName $artifactLabel archived at: ${_relativePath(storedFile.path)}',
    );
  }
}

Future<void> _buildIos(
  List<String> flutterCommand,
  Directory appDir,
  Directory artifactsRoot,
  _BuildSpec spec,
  String version,
) async {
  final flavorName = spec.flavor.name;
  final buildArgs = <String>[
    ...flutterCommand,
    'build',
    'ios',
    '--flavor',
    flavorName,
    '--dart-define=FLAVOR=$flavorName',
  ];

  if (spec.mode == BuildMode.release) {
    buildArgs.addAll(<String>['--release', '--no-codesign']);
  } else {
    buildArgs.addAll(<String>['--debug', '--simulator']);
  }

  await _runProcess(
    buildArgs,
    workingDirectory: appDir.path,
    description: 'flutter IOS (${spec.description})',
  );

  final outputDirPath = spec.mode == BuildMode.release
      ? '${appDir.path}/build/ios/iphoneos'
      : '${appDir.path}/build/ios/iphonesimulator';
  final outputDir = Directory(outputDirPath);
  if (!outputDir.existsSync()) {
    throw CommandError(
      'Expected iOS build directory not found at ${_relativePath(outputDirPath)}.',
      exitCode: 65,
    );
  }

  final appBundle = _findAppBundle(outputDir, flavorName);
  if (appBundle == null) {
    final storedDirectory = _storeDirectoryArtifact(
      outputDir,
      artifactsRoot,
      spec,
      version,
      preferredName: 'ios-${spec.mode.name}-$flavorName',
    );
    Console.success(
      '✅ iOS ${spec.mode.name} $flavorName build output archived at: ${_relativePath(storedDirectory.path)}',
    );
  } else {
    final storedBundle = _storeDirectoryArtifact(
      appBundle,
      artifactsRoot,
      spec,
      version,
      preferredName: p.basename(appBundle.path),
    );
    Console.success(
      '✅ iOS ${spec.mode.name} $flavorName app bundle archived at: ${_relativePath(storedBundle.path)}',
    );
  }
}

Future<void> _runProcess(
  List<String> command, {
  required String workingDirectory,
  required String description,
}) async {
  if (command.isEmpty) {
    throw const CommandError('Internal error: received an empty command.');
  }

  final executable = command.first;
  final arguments = command.length > 1 ? command.sublist(1) : const <String>[];

  Process process;
  try {
    process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      mode: ProcessStartMode.inheritStdio,
      runInShell: true,
    );
  } on ProcessException catch (error) {
    throw CommandError(
      'Failed to start $description: ${error.message}',
      exitCode: error.errorCode,
    );
  }

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw CommandError(
      '$description exited with code $exitCode.',
      exitCode: exitCode,
    );
  }
}

Future<List<String>> _resolveFlutterCommand() async {
  final whichCommand = Platform.isWindows ? 'where' : 'which';
  try {
    final result = await Process.run(
      whichCommand,
      const ['fvm'],
      runInShell: true,
    );
    if (result.exitCode == 0) {
      return const ['fvm', 'flutter'];
    }
  } on ProcessException {
    // Ignore lookup errors and fall back to flutter.
  }
  return const ['flutter'];
}

String _readAppVersion(Directory appDir) {
  final pubspec = File(p.join(appDir.path, 'pubspec.yaml'));
  if (!pubspec.existsSync()) {
    throw const CommandError(
      'Could not find app/pubspec.yaml to resolve version.',
      exitCode: 66,
    );
  }

  for (final line in pubspec.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.startsWith('version:')) {
      final version = trimmed.substring('version:'.length).trim();
      if (version.isNotEmpty) {
        return version;
      }
      break;
    }
  }

  throw const CommandError(
    'Unable to determine app version from app/pubspec.yaml.',
    exitCode: 65,
  );
}

File _storeFileArtifact(
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
  final destName = '${spec.platform.name}-${spec.mode.name}-${spec.flavor.name}-v$version$extension';
  final destination = File(p.join(destinationDir.path, destName));
  if (destination.existsSync()) {
    destination.deleteSync();
  }
  return source.copySync(destination.path);
}

Directory _storeDirectoryArtifact(
  Directory source,
  Directory artifactsRoot,
  _BuildSpec spec,
  String version, {
  String? preferredName,
}) {
  final destinationDir = Directory(
    p.join(
      artifactsRoot.path,
      spec.platform.name,
      spec.mode.name,
      spec.flavor.name,
    ),
  )..createSync(recursive: true);

  final originalName = preferredName ?? p.basename(source.path);
  final extension = p.extension(originalName);
  final nameWithoutExtension = extension.isEmpty ? originalName : p.basenameWithoutExtension(originalName);
  final destName = extension.isEmpty ? '$nameWithoutExtension-v$version' : '$nameWithoutExtension-v$version$extension';
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
      .replaceAll(r'\', r'\')
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
    final name = _basename(entry.path).toLowerCase();
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

String _basename(String path) {
  final sanitized = path.replaceAll(RegExp(r'[\\/]+$'), '');
  if (sanitized.isEmpty) {
    return sanitized;
  }
  final parts = sanitized.split(RegExp(r'[\\/]+'));
  return parts.isEmpty ? sanitized : parts.last;
}

String _relativePath(String absolutePath) {
  final root = Directory.current.absolute.path;
  if (absolutePath.startsWith(root)) {
    final offset = absolutePath.substring(root.length);
    return offset.startsWith(Platform.pathSeparator) ? offset.substring(1) : offset;
  }
  return absolutePath;
}
