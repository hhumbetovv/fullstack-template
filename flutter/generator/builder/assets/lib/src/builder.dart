import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:common_tooling/tooling.dart';
import 'package:dart_style/dart_style.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;

import 'collectors.dart';
import 'generators.dart';
import 'paths.dart';

class AssetsBuilder implements Builder {
  AssetsBuilder({
    required BuilderOptions options,
  }) : paths = AssetPaths.fromOptions(options),
       formatter = DartFormatter(
         languageVersion: DartFormatter.latestLanguageVersion,
       ),
       _packageConfigFuture = _loadPackageConfig();

  final AssetPaths paths;
  final DartFormatter formatter;
  final Future<PackageConfig> _packageConfigFuture;

  @override
  Map<String, List<String>> get buildExtensions => {
    r'$lib$': [
      paths.iconFontClassOutputRelative,
      paths.imagesOutputRelative,
    ],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final packageName = buildStep.inputId.package;
    final packageConfig = await _packageConfigFuture;
    final package = packageConfig.packages.firstWhere(
      (pkg) => pkg.name == packageName,
      orElse: () => throw StateError(
        'Package "$packageName" was not found in package_config.json.',
      ),
    );

    final packageRootPath = normalizeSystemPath(
      package.root.toFilePath(windows: Platform.isWindows),
    );

    final iconsDirAbsolute = _resolveSystemPath(
      packageRootPath,
      paths.iconsInputDir,
    );
    await _renameIconsToSnakeCase(iconsDirAbsolute);

    final fontOutputAbsolute = _resolveSystemPath(
      packageRootPath,
      paths.fontOutputRelative,
    );
    await Directory(p.dirname(fontOutputAbsolute)).create(recursive: true);

    final tempDir = await Directory.systemTemp.createTemp(
      'gen_assets_icon_font_',
    );
    try {
      final tempClassOutput = p.join(tempDir.path, paths.iconClassFileName);
      await Directory(p.dirname(tempClassOutput)).create(recursive: true);

      await _runIconFontGenerator(
        packageRootPath: packageRootPath,
        iconsDirAbsolute: iconsDirAbsolute,
        fontOutputPath: fontOutputAbsolute,
        classOutputPath: tempClassOutput,
        className: paths.iconClassName,
        packageName: packageName,
        normalize: paths.normalizeIcons,
      );

      final rawClassContent = await File(tempClassOutput).readAsString();
      final cleanedClassContent = formatter.format(
        _cleanIconFontContent(rawClassContent),
      );

      await buildStep.writeAsString(
        AssetId(packageName, paths.iconFontClassOutputAbsolute),
        cleanedClassContent,
      );
    } finally {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    }

    final collections = await collectAssets(buildStep, paths);
    final outputs = generateOutputs(collections, paths);

    await buildStep.writeAsString(
      AssetId(packageName, paths.imagesOutputAbsolute),
      formatter.format(outputs.imageContent),
    );
  }

  static Future<PackageConfig> _loadPackageConfig() async {
    final packageConfig = await findPackageConfig(Directory.current);
    if (packageConfig == null) {
      throw StateError(
        'Unable to locate package_config.json for asset builder.',
      );
    }

    return packageConfig;
  }

  static String _resolveSystemPath(String root, String posixRelative) {
    if (posixRelative.isEmpty) {
      return root;
    }

    final segments = posixRelative.split('/')
      ..removeWhere((segment) => segment.isEmpty);
    return p.joinAll(<String>[root, ...segments]);
  }

  Future<void> _renameIconsToSnakeCase(String iconsDirPath) async {
    final iconsDir = Directory(iconsDirPath);
    if (!iconsDir.existsSync()) {
      return;
    }

    final files = <File>[];
    final directories = <Directory>[];

    await for (final entity in iconsDir.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) {
        files.add(entity);
      } else if (entity is Directory) {
        directories.add(entity);
      }
    }

    for (final file in files) {
      if (!file.path.toLowerCase().endsWith('.svg')) {
        continue;
      }
      await _renameFileIfNeeded(file);
    }

    directories
      ..removeWhere((directory) => directory.path == iconsDir.path)
      ..sort((a, b) => b.path.length.compareTo(a.path.length));

    for (final directory in directories) {
      await _renameDirectoryIfNeeded(directory);
    }
  }

  static Future<void> _renameFileIfNeeded(File file) async {
    final parent = file.parent.path;
    final originalName = p.basename(file.path);
    final extension = p.extension(originalName);
    final base = p.basenameWithoutExtension(originalName);
    final normalizedBase = _toSnakeCase(base);
    final newName = '$normalizedBase$extension';
    if (newName == originalName) {
      return;
    }

    final newPath = p.join(parent, newName);
    if (File(newPath).existsSync()) {
      throw StateError(
        'Cannot rename icon "$originalName" to "$newName" because the target already exists.',
      );
    }

    await file.rename(newPath);
  }

  static Future<void> _renameDirectoryIfNeeded(Directory directory) async {
    final parent = directory.parent.path;
    final originalName = p.basename(directory.path);
    final normalizedName = _toSnakeCase(originalName);
    if (normalizedName == originalName) {
      return;
    }

    final newPath = p.join(parent, normalizedName);
    if (Directory(newPath).existsSync()) {
      throw StateError(
        'Cannot rename directory "$originalName" to "$normalizedName" because the target already exists.',
      );
    }

    await directory.rename(newPath);
  }

  static String _toSnakeCase(String value) {
    return value.replaceAll('-', '_');
  }

  static Future<void> _runIconFontGenerator({
    required String packageRootPath,
    required String iconsDirAbsolute,
    required String fontOutputPath,
    required String classOutputPath,
    required String className,
    required String packageName,
    required bool normalize,
  }) async {
    final result = await runDartCommand(
      [
        'pub',
        'global',
        'run',
        'icon_font_generator:generator',
        iconsDirAbsolute,
        fontOutputPath,
        '--output-class-file=$classOutputPath',
        '--class-name=$className',
        '--package=$packageName',
        if (normalize) '--normalize' else '--no-normalize',
        '--recursive',
      ],
      workingDirectory: packageRootPath,
    );

    if (result.exitCode != 0) {
      final stdoutMessage = (result.stdout as Object?)?.toString().trim();
      final stderrMessage = (result.stderr as Object?)?.toString().trim();
      final buffer = StringBuffer(
        'icon_font_generator failed (exit code ${result.exitCode}).',
      );
      if (stdoutMessage?.isNotEmpty ?? false) {
        buffer
          ..write(' stdout: ')
          ..write(stdoutMessage);
      }
      if (stderrMessage?.isNotEmpty ?? false) {
        buffer
          ..write(' stderr: ')
          ..write(stderrMessage);
      }
      throw StateError(buffer.toString());
    }
  }

  static String _cleanIconFontContent(String content) {
    final lines = LineSplitter.split(content).toList();
    final cleaned = <String>[];
    var sawHeader = false;
    var skippingBlockComment = false;

    for (final line in lines) {
      final trimmedLeft = line.trimLeft();

      if (skippingBlockComment) {
        if (trimmedLeft.contains('*/')) {
          skippingBlockComment = false;
        }
        continue;
      }

      final isSlashSlash = trimmedLeft.startsWith('//');
      final isDocComment = trimmedLeft.startsWith('///');

      if (!sawHeader &&
          isSlashSlash &&
          trimmedLeft.toLowerCase().startsWith('// generated code')) {
        cleaned.add(line);
        sawHeader = true;
        continue;
      }

      if (trimmedLeft.startsWith('/*')) {
        skippingBlockComment = !trimmedLeft.contains('*/');
        continue;
      }

      if (isSlashSlash || isDocComment) {
        continue;
      }

      cleaned.add(line);
    }

    return cleaned.join('\n');
  }
}
