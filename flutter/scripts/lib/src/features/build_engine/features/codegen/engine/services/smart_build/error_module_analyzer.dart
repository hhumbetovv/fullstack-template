import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/smart_build/build_log_reader.dart';
import 'package:scripts/src/features/scaffolding/engine/services/yaml_service.dart';

class ErrorModuleAnalyzer {
  ErrorModuleAnalyzer();

  Future<Set<String>> findProblematicModules({
    required Map<String, String> modulePaths,
    required Map<String, BuildLogEntry> logMetadata,
  }) async {
    final issues = <String>{};

    for (final entry in logMetadata.entries) {
      if (entry.value.succeeded == false) {
        issues.add(entry.key);
      }
    }

    for (final entry in modulePaths.entries) {
      final moduleName = entry.key;
      if (issues.contains(moduleName)) {
        continue;
      }

      final usesExporter = await _usesGenExporter(entry.value);
      if (!usesExporter) {
        continue;
      }

      final publicFile = File(
        p.join(_normalize(entry.value), 'lib', 'public.dart'),
      );
      if (!publicFile.existsSync()) {
        issues.add(moduleName);
      }
    }

    return issues;
  }

  final Map<String, Future<bool>> _genExporterCache = <String, Future<bool>>{};

  Future<bool> _usesGenExporter(String modulePath) {
    return _genExporterCache.putIfAbsent(modulePath, () async {
      try {
        final pubspec = await readPubspec(
          '${_normalize(modulePath)}/pubspec.yaml',
        );
        if (pubspec == null) {
          return false;
        }
        bool containsExporter(Map<String, dynamic>? deps) {
          return deps?.keys.any((key) => key == 'gen_exporter') ?? false;
        }

        final deps = pubspec['dependencies'] as Map<String, dynamic>?;
        final devDeps = pubspec['dev_dependencies'] as Map<String, dynamic>?;
        return containsExporter(deps) || containsExporter(devDeps);
      } on Object catch (error) {
        Logger.debug('Failed to parse pubspec for $modulePath: $error');
        return false;
      }
    });
  }

  String _normalize(String rawPath) {
    final normalized = p.normalize(rawPath);
    if (normalized.startsWith('./')) {
      return normalized.substring(2);
    }
    return normalized;
  }
}
