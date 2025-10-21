import 'package:build/build.dart';
import 'package:path/path.dart' as p;

class AssetPaths {
  AssetPaths._({
    required this.assetsDir,
    required this.inputDir,
    required this.outputRelative,
    required this.fontOutputName,
    required this.iconClassFileName,
    required this.iconClassName,
    required this.normalizeIcons,
  });

  factory AssetPaths.fromOptions(BuilderOptions options) {
    final assetsDir = _normalizePath(
      (options.config['assets_dir'] as String?) ?? 'assets',
    );
    final inputDir = _normalizePath(
      (options.config['input'] as String?) ?? assetsDir,
    );
    final rawOutput = _normalizePath(
      (options.config['output_dir'] as String?) ?? 'lib/src/constants',
    );

    var outputRelative = rawOutput;
    if (outputRelative.startsWith('lib/')) {
      outputRelative = outputRelative.substring('lib/'.length);
    } else if (outputRelative == 'lib') {
      outputRelative = '';
    }

    final fontOutputName = (options.config['font_output'] as String?) ??
        (options.config['output'] as String?) ??
        'icons';
    final iconClassFileName = _normalizePath(
      (options.config['icon_class_file'] as String?) ?? 'icons.dart',
    );
    final iconClassName =
        (options.config['icon_class_name'] as String?) ?? 'AppIcons';
    final normalizeIcons = (options.config['normalize'] as bool?) ?? false;

    return AssetPaths._(
      assetsDir: assetsDir,
      inputDir: inputDir,
      outputRelative: outputRelative,
      fontOutputName: fontOutputName,
      iconClassFileName: iconClassFileName,
      iconClassName: iconClassName,
      normalizeIcons: normalizeIcons,
    );
  }

  final String assetsDir;
  final String inputDir;
  final String outputRelative;
  final String fontOutputName;
  final String iconClassFileName;
  final String iconClassName;
  final bool normalizeIcons;

  String get _outputAbsolute => p.posix.join('lib', outputRelative);

  String get iconsDir => p.posix.join(assetsDir, 'icons');
  String get imagesDir => p.posix.join(assetsDir, 'images');

  String get iconsInputDir => p.posix.join(inputDir, 'icons');
  String get fontsDir => p.posix.join(inputDir, 'fonts');

  String get imagesOutputAbsolute => p.posix.join(_outputAbsolute, 'images.dart');
  String get iconFontClassOutputAbsolute =>
      p.posix.join(_outputAbsolute, iconClassFileName);

  String get imagesOutputRelative => p.posix.join(outputRelative, 'images.dart');
  String get iconFontClassOutputRelative =>
      p.posix.join(outputRelative, iconClassFileName);

  String get fontOutputRelative =>
      p.posix.join(fontsDir, '$fontOutputName.otf');
}

String _normalizePath(String value) {
  var normalized = value.replaceAll(r'\', '/');
  normalized = normalized.replaceAll(RegExp('/+'), '/');
  normalized = normalized.replaceAll(RegExp('^/'), '');
  normalized = normalized.replaceAll(RegExp(r'/$'), '');
  return normalized;
}
