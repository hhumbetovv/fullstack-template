import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:scripts/src/domain/models/build_spec.dart';

void storeFileArtifact(
  File source,
  Directory artifactsRoot,
  BuildSpec spec,
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

Directory storeDirectoryArtifact(
  Directory source,
  Directory artifactsRoot,
  BuildSpec spec,
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
