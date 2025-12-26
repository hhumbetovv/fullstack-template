import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/smart_build/analyzer_service.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/smart_build/build_log_reader.dart';
import 'package:scripts/src/features/scaffolding/engine/services/yaml_service.dart';

class ErrorModuleAnalyzer {
  ErrorModuleAnalyzer({AnalyzerService? analyzerService})
    : _analyzerService = analyzerService ?? const AnalyzerService();

  final AnalyzerService _analyzerService;

  Future<Set<String>> findProblematicModules({
    required Map<String, String> modulePaths,
    required Map<String, BuildLogEntry> logMetadata,
  }) async {
    final issues = <String>{};

    for (final entry in logMetadata.entries) {
      final moduleName = entry.key;
      final logEntry = entry.value;
      if (logEntry.succeeded == false) {
        issues.add(moduleName);
      }

      final unresolvedSources = await _findModulesFromUnresolvedPublicImports(
        logEntry.path,
      );
      for (final candidate in unresolvedSources) {
        if (modulePaths.containsKey(candidate)) {
          issues.add(candidate);
        }
      }
    }

    final analyzerModules = await _analyzerService.findModulesWithErrors(
      modulePaths: modulePaths,
    );
    issues.addAll(analyzerModules);

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
  static final List<RegExp> _missingPublicImportPatterns = <RegExp>[
    RegExp(
      r"Target of URI doesn't exist: 'package:([A-Za-z0-9_]+)/public\.dart'",
    ),
    RegExp(
      r"Not found: 'package:([A-Za-z0-9_]+)/public\.dart'",
    ),
  ];

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

  Future<Set<String>> _findModulesFromUnresolvedPublicImports(
    String logPath,
  ) async {
    final file = File(logPath);
    if (!file.existsSync()) {
      return const <String>{};
    }
    try {
      final contents = await file.readAsString();
      final matches = <String>{};
      for (final pattern in _missingPublicImportPatterns) {
        for (final match in pattern.allMatches(contents)) {
          final moduleName = match.group(1);
          if (moduleName != null && moduleName.isNotEmpty) {
            matches.add(moduleName);
          }
        }
      }
      return matches;
    } on Object catch (error) {
      Logger.debug(
        'Failed to parse unresolved imports from $logPath: $error',
      );
      return const <String>{};
    }
  }
}
