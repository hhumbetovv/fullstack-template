import 'dart:async';

import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import 'models.dart';
import 'naming.dart';
import 'paths.dart';

const _supportedImageExtensions = {'png', 'jpg', 'jpeg', 'svg'};
const _supportedLottieExtensions = {'json'};

Future<AssetCollections> collectAssets(
  BuildStep buildStep,
  AssetPaths paths,
) async {
  final icons = await _collectIcons(buildStep, paths);
  final images = await _collectImages(buildStep, paths);
  final lotties = await _collectLotties(buildStep, paths);

  return AssetCollections(
    icons: icons,
    images: images,
    lotties: lotties,
  );
}

Future<List<IconEntry>> _collectIcons(
  BuildStep buildStep,
  AssetPaths paths,
) async {
  final glob = Glob('${paths.iconsDir}/**');
  final iconBases = <String>{};

  await for (final asset in buildStep.findAssets(glob)) {
    final exists = await buildStep.canRead(asset);
    if (!exists) {
      continue;
    }

    final extension = p.posix
        .extension(asset.path)
        .replaceFirst('.', '')
        .toLowerCase();
    if (extension != 'svg') {
      continue;
    }

    final relative = p.posix.relative(asset.path, from: paths.iconsDir);
    if (relative.startsWith('..') || relative.isEmpty) {
      continue;
    }

    final base = p.posix.withoutExtension(relative);
    iconBases.add(base);
  }

  final registry = NameRegistry();

  return iconBases.sorted((a, b) => a.compareTo(b)).map((base) {
    final enumName = registry.allocate(
      toLowerCamel(base),
      prefix: 'icon',
    );

    return IconEntry(
      enumName: enumName,
      assetName: base,
    );
  }).toList();
}

Future<List<ImageEntry>> _collectImages(
  BuildStep buildStep,
  AssetPaths paths,
) async {
  final glob = Glob('${paths.imagesDir}/**');
  final images = <String>{};

  await for (final asset in buildStep.findAssets(glob)) {
    final exists = await buildStep.canRead(asset);
    if (!exists) {
      continue;
    }

    final extension = p.posix
        .extension(asset.path)
        .replaceFirst('.', '')
        .toLowerCase();
    if (!_supportedImageExtensions.contains(extension)) {
      continue;
    }

    final relative = p.posix.relative(asset.path, from: paths.imagesDir);
    if (relative.startsWith('..') || relative.isEmpty) {
      continue;
    }

    final base = p.posix.withoutExtension(relative);
    images.add(base);
  }

  final registry = NameRegistry();

  return images.sorted((a, b) => a.compareTo(b)).map((base) {
    final enumName = registry.allocate(
      toLowerCamel(base),
      prefix: 'image',
    );

    return ImageEntry(
      enumName: enumName,
      assetName: base,
    );
  }).toList();
}

Future<List<LottieEntry>> _collectLotties(
  BuildStep buildStep,
  AssetPaths paths,
) async {
  final glob = Glob('${paths.lottieDir}/**');
  final lotties = <String>{};

  await for (final asset in buildStep.findAssets(glob)) {
    final exists = await buildStep.canRead(asset);
    if (!exists) {
      continue;
    }

    final extension = p.posix
        .extension(asset.path)
        .replaceFirst('.', '')
        .toLowerCase();
    if (!_supportedLottieExtensions.contains(extension)) {
      continue;
    }

    final relative = p.posix.relative(asset.path, from: paths.lottieDir);
    if (relative.startsWith('..') || relative.isEmpty) {
      continue;
    }

    final base = p.posix.withoutExtension(relative);
    lotties.add(base);
  }

  final registry = NameRegistry();

  return lotties.sorted((a, b) => a.compareTo(b)).map((base) {
    final enumName = registry.allocate(
      toLowerCamel(base),
      prefix: 'lottie',
    );

    return LottieEntry(
      enumName: enumName,
      assetName: base,
    );
  }).toList();
}
