import 'dart:io';

import 'package:path/path.dart' as p;

const Set<String> defaultExcludedSegments = {
  '.git',
  '.dart_tool',
  '.fvm',
  '.idea',
  'build',
  'node_modules',
  '.gradle',
  'Flutter',
};

class DirectoryWalker {
  DirectoryWalker({
    Directory? root,
    Set<String>? excludedSegments,
  }) : root = root ?? Directory.current,
       excludedSegments = excludedSegments ?? defaultExcludedSegments;

  final Directory root;
  final Set<String> excludedSegments;

  Iterable<Directory> traverse() sync* {
    final queue = <Directory>[root];
    final visited = <String>{};

    while (queue.isNotEmpty) {
      final directory = queue.removeLast();
      final normalized = p.normalize(directory.absolute.path);
      if (!visited.add(normalized)) continue;

      if (_shouldSkip(normalized) &&
          normalized != p.normalize(root.absolute.path)) {
        continue;
      }

      yield directory;

      try {
        for (final entity in directory.listSync(followLinks: false)) {
          if (entity is Directory) {
            queue.add(entity);
          }
        }
      } on Exception {
        // Ignore directories that cannot be listed.
        continue;
      }
    }
  }

  Iterable<File> findFilesNamed(String fileName) sync* {
    for (final directory in traverse()) {
      try {
        for (final entity in directory.listSync(followLinks: false)) {
          if (entity is File && p.basename(entity.path) == fileName) {
            yield entity;
          }
        }
      } on Exception {
        continue;
      }
    }
  }

  bool _shouldSkip(String normalizedPath) {
    final segments = p.split(normalizedPath);
    return segments.any(excludedSegments.contains);
  }
}
