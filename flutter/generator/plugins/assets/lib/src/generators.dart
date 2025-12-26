import 'models.dart';
import 'paths.dart';

const _header =
    '// GENERATED CODE - DO NOT MODIFY BY HAND\n// ignore_for_file: type=lint';

AssetOutputs generateOutputs(
  AssetCollections collections,
  AssetPaths paths,
) {
  final imageContent = _generateImagesContent(
    collections.images,
    paths.imagesDir,
  );
  final lottieContent = _generateLottiesContent(
    collections.lotties,
    paths.lottieDir,
  );

  return AssetOutputs(
    imageContent: imageContent,
    lottieContent: lottieContent,
  );
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

String _generateLottiesContent(List<LottieEntry> lotties, String lottieDir) {
  final buffer = StringBuffer()
    ..writeln(_header)
    ..writeln()
    ..writeln('enum AppLotties {');

  if (lotties.isEmpty) {
    buffer
      ..writeln('  // ignore: unused_field')
      ..writeln("  _placeholder('_placeholder');");
  } else {
    for (var i = 0; i < lotties.length; i++) {
      final lottie = lotties[i];
      final suffix = i == lotties.length - 1 ? ';' : ',';
      buffer.writeln("  ${lottie.enumName}('${lottie.assetName}')$suffix");
    }
  }

  buffer
    ..writeln()
    ..writeln('  const AppLotties(this._name);')
    ..writeln()
    ..writeln('  final String _name;')
    ..writeln()
    ..writeln("  String get json => '$lottieDir/\$_name.json';")
    ..writeln('}');

  return buffer.toString();
}
