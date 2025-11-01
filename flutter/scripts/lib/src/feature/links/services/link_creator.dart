import 'dart:io';

import 'package:common_tooling/tooling.dart';
import 'package:path/path.dart' as p;
import 'package:scripts/src/core/logging/console.dart';

class LinkSummary {
  const LinkSummary({
    required this.created,
    required this.failed,
    required this.outputDir,
  });

  final int created;
  final int failed;
  final String outputDir;
}

Future<LinkSummary> createSymlinks({
  required String fileName,
  required String outputDir,
}) async {
  final root = Directory.current;
  final output = Directory(outputDir);
  if (output.existsSync()) {
    _cleanDirectory(output);
  } else {
    output.createSync(recursive: true);
  }

  var created = 0;
  var failed = 0;

  for (final file in _findFiles(root, fileName)) {
    final relativePath = p.relative(file.path, from: root.path);
    final sanitized = _sanitizePath(relativePath);
    final symlinkPath = _uniquePath(output, sanitized);
    final link = Link(symlinkPath);
    final target = File(file.path).absolute.path;

    try {
      if (link.existsSync()) {
        link.deleteSync();
      }
      link.createSync(target, recursive: false);
      Console.success('✓ $relativePath -> ${p.basename(symlinkPath)}');
      created++;
    } on Exception catch (error) {
      Console.error('✗ Failed to link $relativePath: $error');
      failed++;
    }
  }

  return LinkSummary(created: created, failed: failed, outputDir: outputDir);
}

Iterable<File> _findFiles(Directory root, String fileName) {
  final walker = DirectoryWalker(root: root);
  final files = <File>[];
  for (final file in walker.findFilesNamed(fileName)) {
    files.add(file);
  }
  return files;
}

void _cleanDirectory(Directory directory) {
  for (final entity in directory.listSync()) {
    entity.deleteSync(recursive: true);
  }
}

String _sanitizePath(String relativePath) {
  var sanitized = relativePath.replaceAll(RegExp(r'^\.*/'), '');
  sanitized = sanitized.replaceAll(RegExp(r'[\\/]'), '_');
  if (sanitized.isEmpty) {
    sanitized = 'root';
  }
  if (!sanitized.endsWith('.yaml')) {
    sanitized = '$sanitized.yaml';
  }
  return sanitized;
}

String _uniquePath(Directory output, String fileName) {
  final baseName = fileName.replaceAll('.yaml', '');
  var candidate = fileName;
  var counter = 1;
  while (File(p.join(output.path, candidate)).existsSync() ||
      Link(p.join(output.path, candidate)).existsSync()) {
    candidate = '${baseName}_${counter++}.yaml';
  }
  return p.join(output.path, candidate);
}
