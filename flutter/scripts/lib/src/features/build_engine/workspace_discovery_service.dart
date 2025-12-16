import 'dart:io';

import 'package:common_tooling/tooling.dart';
import 'package:path/path.dart' as p;
import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/features/build_engine/domain/models/module_descriptor.dart';
import 'package:scripts/src/features/build_engine/module_discovery_port.dart';

class WorkspaceDiscoveryService implements ModuleDiscoveryPort {
  const WorkspaceDiscoveryService();

  @override
  Future<List<ModuleDescriptor>> discover({
    required bool includeNonBuildRunner,
  }) async {
    final modules = <ModuleDescriptor>[];
    final walker = DirectoryWalker(root: Directory.current);
    final templatesRoot = p.normalize(
      p.join(Directory.current.path, 'scripts', 'templates'),
    );
    final hasTemplates = Directory(templatesRoot).existsSync();
    final seen = <String>{};

    for (final directory in walker.traverse()) {
      final normalizedPath = p.normalize(directory.absolute.path);
      if (!seen.add(normalizedPath)) {
        continue;
      }
      if (hasTemplates && _isUnderTemplate(normalizedPath, templatesRoot)) {
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
        ModuleDescriptor(
          name: name,
          path: directory.absolute.path,
          hasBuildRunner: hasBuildRunner,
        ),
      );
    }

    modules.sort((a, b) => a.name.compareTo(b.name));
    return modules;
  }

  @override
  ModuleDescriptor? find(List<ModuleDescriptor> modules, String target) {
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
    } on Object catch (error) {
      Console.warning('Failed to read ${pubspec.path}: $error');
    }
    return null;
  }

  bool _containsBuildRunner(File pubspec) {
    try {
      return pubspec.readAsStringSync().contains('build_runner');
    } on Object {
      return false;
    }
  }

  bool _isUnderTemplate(String path, String templatesRoot) {
    return path == templatesRoot ||
        path.startsWith('$templatesRoot${Platform.pathSeparator}');
  }
}
