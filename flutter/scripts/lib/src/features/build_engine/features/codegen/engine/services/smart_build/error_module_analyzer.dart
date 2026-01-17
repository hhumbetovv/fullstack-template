import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/smart_build/analyzer_service.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/smart_build/build_log_reader.dart';

class ErrorModuleAnalyzer {
  ErrorModuleAnalyzer({
    required AnalyzerService analyzerService,
  }) : _analyzerService = analyzerService;

  final AnalyzerService _analyzerService;

  Future<Set<String>> findProblematicModules({
    required Map<String, String> modulePaths,
    required Map<String, BuildLogEntry> logMetadata,
  }) async {
    final issues = <String>{}
      ..addAll(
        await _collectModulesFromAnalyzer(modulePaths),
      )
      ..addAll(
        await _collectModulesFromLogs(
          modulePaths: modulePaths,
          logMetadata: logMetadata,
        ),
      );

    if (issues.isNotEmpty) {
      final sorted = issues.toList()..sort();
      Logger.info('Problematic modules detected: ${sorted.join(', ')}');
    }

    return issues;
  }

  Future<Set<String>> _collectModulesFromAnalyzer(
    Map<String, String> modulePaths,
  ) async {
    final report = await _analyzerService.runAnalyze();
    if (report == null) {
      return const <String>{};
    }

    final workspaceRoot = Directory.current.path;
    final issues = <String>{};
    for (final issue in report.issues) {
      if (!issue.isActionable) continue;

      final owner = _resolveModuleForFile(
        issue.filePath,
        modulePaths,
        workspaceRoot,
      );
      if (owner != null) {
        issues.add(owner);
      }

      for (final package in _extractPackagesFromMessage(issue.message)) {
        if (modulePaths.containsKey(package)) {
          issues.add(package);
        }
      }
    }

    return issues;
  }

  Future<Set<String>> _collectModulesFromLogs({
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

      final unresolvedSources = await _findModulesFromUnresolvedImports(
        ownerModule: moduleName,
        logPath: logEntry.path,
      );

      for (final candidate in unresolvedSources) {
        if (modulePaths.containsKey(candidate)) {
          issues.add(candidate);
        }
      }
    }

    return issues;
  }

  String? _resolveModuleForFile(
    String filePath,
    Map<String, String> modulePaths,
    String workspaceRoot,
  ) {
    final normalizedFile = p.normalize(filePath);
    for (final entry in modulePaths.entries) {
      final moduleRoot = _absoluteModulePath(entry.value, workspaceRoot);
      if (normalizedFile == moduleRoot || normalizedFile.startsWith('$moduleRoot${p.separator}')) {
        return entry.key;
      }
    }
    return null;
  }

  String _absoluteModulePath(String rawPath, String workspaceRoot) {
    var candidate = rawPath.trim();
    if (candidate.startsWith('./')) {
      candidate = candidate.substring(2);
    }

    if (p.isAbsolute(candidate)) {
      return p.normalize(candidate);
    }
    return p.normalize(p.join(workspaceRoot, candidate));
  }

  Iterable<String> _extractPackagesFromMessage(String message) sync* {
    for (final pattern in _unresolvedImportPatterns) {
      for (final match in pattern.allMatches(message)) {
        final moduleName = match.group(1);
        if (moduleName != null && moduleName.isNotEmpty) {
          yield moduleName;
        }
      }
    }
  }

  Future<Set<String>> _findModulesFromUnresolvedImports({
    required String ownerModule,
    required String logPath,
  }) async {
    final file = File(logPath);
    if (!file.existsSync()) {
      return const <String>{};
    }
    try {
      final contents = await file.readAsString();
      final matches = <String>{};
      var foundUnresolvedImport = false;
      for (final pattern in _unresolvedImportPatterns) {
        for (final match in pattern.allMatches(contents)) {
          final moduleName = match.group(1);
          if (moduleName != null && moduleName.isNotEmpty) {
            matches.add(moduleName);
          }
          foundUnresolvedImport = true;
        }
      }
      if (foundUnresolvedImport) {
        matches.add(ownerModule);
      }
      return matches;
    } on Object catch (error) {
      Logger.debug('Failed to parse unresolved imports from $logPath: $error');
      return <String>{ownerModule};
    }
  }
}

final List<RegExp> _unresolvedImportPatterns = <RegExp>[
  RegExp(
    "Target of URI doesn't exist: 'package:([A-Za-z0-9_]+)/[^']+'",
  ),
  RegExp(
    "Couldn't import 'package:([A-Za-z0-9_]+)/[^']+'",
  ),
  RegExp(
    "Not found: 'package:([A-Za-z0-9_]+)/[^']+'",
  ),
  RegExp(
    "URI with scheme 'package' not found: 'package:([A-Za-z0-9_]+)/[^']+'",
  ),
];
