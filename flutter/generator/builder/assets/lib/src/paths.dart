import 'package:build/build.dart';
import 'package:path/path.dart' as p;

class AssetPaths {
  AssetPaths._({
    required this.assetsDir,
    required this.outputRelative,
  });

  factory AssetPaths.fromOptions(BuilderOptions options) {
    final assetsDir = _normalizePath(
      (options.config['assets_dir'] as String?) ?? 'assets',
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

    return AssetPaths._(
      assetsDir: assetsDir,
      outputRelative: outputRelative,
    );
  }

  final String assetsDir;
  final String outputRelative;

  String get _outputAbsolute => p.posix.join('lib', outputRelative);

  String get iconsDir => p.posix.join(assetsDir, 'icons');
  String get imagesDir => p.posix.join(assetsDir, 'images');

  String get iconsOutputAbsolute => p.posix.join(_outputAbsolute, 'icons.dart');
  String get imagesOutputAbsolute => p.posix.join(_outputAbsolute, 'images.dart');

  String get iconsOutputRelative => p.posix.join(outputRelative, 'icons.dart');
  String get imagesOutputRelative => p.posix.join(outputRelative, 'images.dart');
}

String _normalizePath(String value) {
  var normalized = value.replaceAll(r'\', '/');
  normalized = normalized.replaceAll(RegExp('/+'), '/');
  normalized = normalized.replaceAll(RegExp('^/'), '');
  normalized = normalized.replaceAll(RegExp(r'/$'), '');
  return normalized;
}
