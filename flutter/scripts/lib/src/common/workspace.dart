import 'dart:io';

import 'package:path/path.dart' as p;

import 'console.dart';

class ModuleInfo {
  ModuleInfo({
    required this.name,
    required this.path,
    required this.hasBuildRunner,
  });

  final String name;
  final String path;
  final bool hasBuildRunner;

  Directory get directory => Directory(path);
}

final Set<String> _excludedDirs = {
  '.git',
  '.dart_tool',
  '.fvm',
  '.idea',
  'build',
  'node_modules',
  '.gradle',
  'Flutter',
};

bool _shouldSkipDirectory(String path) {
  final segments = p.split(path);
  return segments.any(_excludedDirs.contains);
}

Future<List<ModuleInfo>> discoverModules({
  bool includeNonBuildRunner = true,
}) async {
  final root = Directory.current;
  final modules = <ModuleInfo>[];
  final queue = <Directory>[root];
  final visited = <String>{};

  while (queue.isNotEmpty) {
    final dir = queue.removeLast();
    final normalized = p.normalize(dir.absolute.path);
    if (!visited.add(normalized)) continue;
    if (_shouldSkipDirectory(normalized) && dir.path != root.path) {
      continue;
    }

    final entries = dir.listSync(followLinks: false);
    File? pubspec;
    for (final entry in entries) {
      if (entry is File && p.basename(entry.path) == 'pubspec.yaml') {
        pubspec = entry;
        break;
      }
    }

    if (pubspec != null) {
      final name = _extractModuleName(pubspec) ?? p.basename(dir.path);
      final hasBuildRunner = _containsBuildRunner(pubspec);
      if (includeNonBuildRunner || hasBuildRunner) {
        modules.add(
          ModuleInfo(
            name: name,
            path: dir.absolute.path,
            hasBuildRunner: hasBuildRunner,
          ),
        );
      }
      // continue searching children for nested modules
    }

    for (final entry in entries) {
      if (entry is Directory) {
        queue.add(entry);
      }
    }
  }

  modules.sort((a, b) => a.name.compareTo(b.name));
  return modules;
}

String? _extractModuleName(File pubspec) {
  try {
    for (final line in pubspec.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.startsWith('name:')) {
        final parts = trimmed.split(':');
        if (parts.length >= 2) {
          return parts[1].trim();
        }
      }
    }
  } on Exception catch (error) {
    Console.warning('Failed to read ${pubspec.path}: $error');
  }
  return null;
}

bool _containsBuildRunner(File pubspec) {
  try {
    return pubspec.readAsStringSync().contains('build_runner');
  } on Exception {
    return false;
  }
}

ModuleInfo? findModule(List<ModuleInfo> modules, String target) {
  final byName = modules.where((module) => module.name == target);
  if (byName.isNotEmpty) return byName.first;

  final normalized = p.normalize(p.absolute(target));
  for (final module in modules) {
    if (p.normalize(module.path) == normalized) {
      return module;
    }
  }

  final withDot = p.normalize(p.absolute('./$target'));
  for (final module in modules) {
    if (p.normalize(module.path) == withDot) {
      return module;
    }
  }

  return null;
}
