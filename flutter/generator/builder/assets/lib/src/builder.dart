import 'dart:async';

import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';

import 'collectors.dart';
import 'generators.dart';
import 'paths.dart';

class AssetsBuilder implements Builder {
  AssetsBuilder({
    required BuilderOptions options,
  }) : paths = AssetPaths.fromOptions(options),
       formatter = DartFormatter(
         languageVersion: DartFormatter.latestLanguageVersion,
       );

  final AssetPaths paths;
  final DartFormatter formatter;

  @override
  Map<String, List<String>> get buildExtensions => {
    r'$lib$': [
      paths.iconsOutputRelative,
      paths.imagesOutputRelative,
    ],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final packageName = buildStep.inputId.package;
    final collections = await collectAssets(buildStep, paths);
    final outputs = generateOutputs(collections, paths);

    Future<void> write(String outputPath, String content) {
      return buildStep.writeAsString(
        AssetId(packageName, outputPath),
        formatter.format(content),
      );
    }

    await Future.wait(
      [
        write(paths.iconsOutputAbsolute, outputs.iconContent),
        write(paths.imagesOutputAbsolute, outputs.imageContent),
      ],
    );
  }
}
