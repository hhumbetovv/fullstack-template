import 'dart:io';

import 'package:path/path.dart' as p;

class IconNormalizer {
  Future<void> renameTree(String iconsDirPath) async {
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

  Future<void> _renameFileIfNeeded(File file) async {
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

  Future<void> _renameDirectoryIfNeeded(Directory directory) async {
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

  String _toSnakeCase(String value) {
    return value.replaceAll('-', '_');
  }
}
