import 'dart:io';

import 'package:common_tooling/tooling.dart';
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

Future<List<ModuleInfo>> discoverModules({
  bool includeNonBuildRunner = true,
}) async {
  final modules = <ModuleInfo>[];
  final walker = DirectoryWalker(root: Directory.current);
  final seen = <String>{};

  for (final directory in walker.traverse()) {
    final normalizedPath = p.normalize(directory.absolute.path);
    if (!seen.add(normalizedPath)) {
      continue;
    }
    final pubspec = File(p.join(directory.path, 'pubspec.yaml'));
    if (!pubspec.existsSync()) continue;

    final name = _extractModuleName(pubspec) ?? p.basename(directory.path);
    final hasBuildRunner = _containsBuildRunner(pubspec);
    if (!includeNonBuildRunner && !hasBuildRunner) {
      continue;
    }

    modules.add(
      ModuleInfo(
        name: name,
        path: directory.absolute.path,
        hasBuildRunner: hasBuildRunner,
      ),
    );
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
