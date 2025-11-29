import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:common_tooling/tooling.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;

import 'collectors.dart';
import 'generators.dart';
import 'paths.dart';
import 'services/icon_font_service.dart';
import 'services/icon_normalizer.dart';
import 'services/package_resolver.dart';

class AssetsBuilder implements Builder {
  AssetsBuilder({
    required BuilderOptions options,
    PackageResolver? packageResolver,
    IconNormalizer? iconNormalizer,
    IconFontService? iconFontService,
  }) : paths = AssetPaths.fromOptions(options),
       formatter = DartFormatter(
         languageVersion: DartFormatter.latestLanguageVersion,
       ),
       _packageResolver = packageResolver ?? PackageResolver(),
       _iconNormalizer = iconNormalizer ?? IconNormalizer(),
       _iconFontService = iconFontService ?? IconFontService();

  final AssetPaths paths;
  final DartFormatter formatter;
  final PackageResolver _packageResolver;
  final IconNormalizer _iconNormalizer;
  final IconFontService _iconFontService;

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
    final package = await _packageResolver.resolve(packageName);

    final packageRootPath = normalizeSystemPath(
      package.root.toFilePath(windows: Platform.isWindows),
    );

    final iconsDirAbsolute = _resolveSystemPath(
      packageRootPath,
      paths.iconsInputDir,
    );
    await _iconNormalizer.renameTree(iconsDirAbsolute);

    final fontOutputAbsolute = _resolveSystemPath(
      packageRootPath,
      paths.fontOutputRelative,
    );
    await Directory(p.dirname(fontOutputAbsolute)).create(recursive: true);

    final rawClassContent = await _iconFontService.generate(
      packageRootPath: packageRootPath,
      packageName: packageName,
      iconsDirAbsolute: iconsDirAbsolute,
      fontOutputPath: fontOutputAbsolute,
      className: paths.iconClassName,
      classFileName: paths.iconClassFileName,
      normalize: paths.normalizeIcons,
    );

    final cleanedClassContent = formatter.format(rawClassContent);

    await buildStep.writeAsString(
      AssetId(packageName, paths.iconFontClassOutputAbsolute),
      cleanedClassContent,
    );

    final collections = await collectAssets(buildStep, paths);
    final outputs = generateOutputs(collections, paths);

    await buildStep.writeAsString(
      AssetId(packageName, paths.imagesOutputAbsolute),
      formatter.format(outputs.imageContent),
    );
  }

  static String _resolveSystemPath(String root, String posixRelative) {
    if (posixRelative.isEmpty) {
      return root;
    }

    final segments = posixRelative.split('/')
      ..removeWhere((segment) => segment.isEmpty);
    return p.joinAll(<String>[root, ...segments]);
  }
}
