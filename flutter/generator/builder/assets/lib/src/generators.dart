import 'models.dart';
import 'paths.dart';

const _header = '// GENERATED CODE - DO NOT MODIFY BY HAND';

AssetOutputs generateOutputs(
  AssetCollections collections,
  AssetPaths paths,
) {
  final iconContent = _generateIconsContent(collections.icons, paths.iconsDir);
  final imageContent = _generateImagesContent(
    collections.images,
    paths.imagesDir,
  );

  return AssetOutputs(
    iconContent: iconContent,
    imageContent: imageContent,
  );
}

String _generateIconsContent(List<IconEntry> icons, String iconsDir) {
  final buffer = StringBuffer()
    ..writeln(_header)
    ..writeln()
    ..writeln('enum AppIcons {');

  if (icons.isEmpty) {
    buffer
      ..writeln('  // ignore: unused_field')
      ..writeln("  _placeholder('_placeholder');");
  } else {
    for (var i = 0; i < icons.length; i++) {
      final icon = icons[i];
      final suffix = i == icons.length - 1 ? ';' : ',';
      buffer.writeln("  ${icon.enumName}('${icon.assetName}')$suffix");
    }
  }

  buffer
    ..writeln()
    ..writeln('  const AppIcons(this._name);')
    ..writeln()
    ..writeln('  final String _name;')
    ..writeln()
    ..writeln("  String get path => '$iconsDir/\$_name.svg';")
    ..writeln('}');

  return buffer.toString();
}

String _generateImagesContent(List<ImageEntry> images, String imagesDir) {
  final buffer = StringBuffer()
    ..writeln(_header)
    ..writeln()
    ..writeln('enum AppImages {');

  if (images.isEmpty) {
    buffer
      ..writeln('  // ignore: unused_field')
      ..writeln("  _placeholder('_placeholder');");
  } else {
    for (var i = 0; i < images.length; i++) {
      final image = images[i];
      final suffix = i == images.length - 1 ? ';' : ',';
      buffer.writeln("  ${image.enumName}('${image.assetName}')$suffix");
    }
  }

  buffer
    ..writeln()
    ..writeln('  const AppImages(this._name);')
    ..writeln()
    ..writeln('  final String _name;')
    ..writeln()
    ..writeln("  String get png => '$imagesDir/\$_name.png';")
    ..writeln("  String get jpg => '$imagesDir/\$_name.jpg';")
    ..writeln("  String get svg => '$imagesDir/\$_name.svg';")
    ..writeln('}');

  return buffer.toString();
}
