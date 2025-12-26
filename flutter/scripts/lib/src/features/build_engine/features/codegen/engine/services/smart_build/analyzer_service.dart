import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:common_tooling/tooling.dart';
import 'package:path/path.dart' as p;
import 'package:scripts/src/core/logging/logging.dart';

class AnalyzerService {
  const AnalyzerService();

  Future<Set<String>> findModulesWithErrors({
    required Map<String, String> modulePaths,
  }) async {
    try {
      final issues = await _runAnalyzer();
      if (issues.isEmpty) {
        return const <String>{};
      }
      final normalizedModules = <String, String>{
        for (final entry in modulePaths.entries)
          entry.key: _absolutize(entry.value),
      };

      final failingModules = <String>{};
      for (final issue in issues) {
        final moduleFromFile = _matchModule(issue.filePath, normalizedModules);
        if (moduleFromFile != null) {
          failingModules.add(moduleFromFile);
        }
        for (final moduleName in _extractModulesFromMessage(issue.message)) {
          if (modulePaths.containsKey(moduleName)) {
            failingModules.add(moduleName);
          }
        }
      }
      return failingModules;
    } on Object catch (error, stackTrace) {
      Logger.debug('Analyzer execution failed: $error');
      Logger.verbose(stackTrace.toString());
      return const <String>{};
    }
  }

  Future<List<_AnalyzerIssue>> _runAnalyzer() async {
    Logger.info('🔍 Running `dart analyze` for smart-build...');
    final process = await startDartCommand(
      const ['analyze', '--format', 'machine'],
    );

    final stdoutFuture = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .toList();
    final stderrFuture = process.stderr.transform(utf8.decoder).join();

    final exitCode = await process.exitCode;
    final stdoutLines = await stdoutFuture;
    final stderrOutput = await stderrFuture;

    if (stderrOutput.isNotEmpty) {
      Logger.verbose(stderrOutput);
    }

    if (stdoutLines.isEmpty) {
      if (exitCode != 0) {
        Logger.debug('Analyzer exited with $exitCode and no output.');
      }
      return const <_AnalyzerIssue>[];
    }

    final issues = _parseMachineOutput(stdoutLines);
    if (issues.isEmpty && exitCode != 0) {
      Logger.debug('Analyzer exited with $exitCode but no issues parsed.');
    }
    return issues;
  }

  List<_AnalyzerIssue> _parseMachineOutput(List<String> lines) {
    final issues = <_AnalyzerIssue>[];
    for (final line in lines) {
      if (!line.startsWith('error|')) {
        continue;
      }
      final parts = line.split('|');
      if (parts.length < 8) {
        continue;
      }
      final filePath = parts[3];
      final message = parts.sublist(7).join('|');
      issues.add(
        _AnalyzerIssue(
          filePath: filePath,
          message: message,
        ),
      );
    }
    return issues;
  }

  String? _matchModule(
    String filePath,
    Map<String, String> normalizedModules,
  ) {
    if (filePath.trim().isEmpty) {
      return null;
    }
    final absFile = _absolutize(filePath);
    for (final entry in normalizedModules.entries) {
      final root = entry.value;
      if (absFile == root || absFile.startsWith('$root${p.separator}')) {
        return entry.key;
      }
    }
    return null;
  }

  Iterable<String> _extractModulesFromMessage(String message) sync* {
    for (final pattern in _missingPublicImportPatterns) {
      for (final match in pattern.allMatches(message)) {
        final moduleName = match.group(1);
        if (moduleName != null && moduleName.isNotEmpty) {
          yield moduleName;
        }
      }
    }
  }

  String _absolutize(String rawPath) {
    var normalized = p.normalize(rawPath);
    if (normalized.startsWith('./')) {
      normalized = normalized.substring(2);
    }
    if (!p.isAbsolute(normalized)) {
      normalized = p.normalize(p.join(Directory.current.path, normalized));
    }
    return normalized;
  }
}

class _AnalyzerIssue {
  const _AnalyzerIssue({
    required this.filePath,
    required this.message,
  });

  final String filePath;
  final String message;
}

final List<RegExp> _missingPublicImportPatterns = <RegExp>[
  RegExp(
    r"Target of URI doesn't exist: 'package:([A-Za-z0-9_]+)/public\.dart'",
  ),
  RegExp(
    r"Not found: 'package:([A-Za-z0-9_]+)/public\.dart'",
  ),
];
