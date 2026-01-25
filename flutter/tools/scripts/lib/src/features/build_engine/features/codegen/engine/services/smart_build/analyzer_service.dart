import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:scripts/src/core/logging/logging.dart';
import 'package:tools_common/tooling.dart';

class AnalyzerService {
  const AnalyzerService();

  Future<AnalyzerReport?> runAnalyze({
    bool fatalWarnings = true,
  }) async {
    Logger.info('🔍 Running analyzer (fatal warnings enabled)...');

    final args = <String>['analyze', '--format', 'machine'];
    if (fatalWarnings) {
      args.add('--fatal-warnings');
    }

    try {
      final result = await runDartCommand(args);
      final stdout = _coerceToString(result.stdout);
      final stderr = _coerceToString(result.stderr);
      final issues = _parseMachineOutput(stdout);
      final actionableIssues = issues.where((issue) => issue.isActionable);

      if (actionableIssues.isEmpty) {
        Logger.success('Analyzer completed with no blocking issues.');
      } else {
        Logger.warning(
          'Analyzer reported ${actionableIssues.length} blocking issue(s).',
        );
        Logger.warning(
          'Run `fvm dart analyze` locally for detailed diagnostics.',
        );
      }

      if (result.exitCode != 0 && issues.isEmpty) {
        Logger.warning(
          'dart analyze exited with code ${result.exitCode} but produced no '
          'machine-readable issues. stderr:\n$stderr',
        );
      }

      return AnalyzerReport(
        exitCode: result.exitCode,
        stdout: stdout,
        stderr: stderr,
        issues: issues,
      );
    } on Object catch (error, stackTrace) {
      Logger.error('Failed to run dart analyze: $error');
      Logger.debug(stackTrace.toString());
      return null;
    }
  }

  List<AnalyzerIssue> _parseMachineOutput(String output) {
    final issues = <AnalyzerIssue>[];
    for (final rawLine in output.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final segments = _splitMachineLine(line);
      if (segments == null) continue;

      final severity = AnalyzerSeverity.fromLabel(segments[0]);
      final code = segments[2];
      final filePath = segments[3];
      final lineNumber = int.tryParse(segments[4]) ?? 0;
      final columnNumber = int.tryParse(segments[5]) ?? 0;
      final length = int.tryParse(segments[6]) ?? 0;
      final message = segments[7].trim();

      issues.add(
        AnalyzerIssue(
          severity: severity,
          code: code,
          filePath: filePath,
          line: lineNumber,
          column: columnNumber,
          length: length,
          message: message,
        ),
      );
    }
    return issues;
  }

  List<String>? _splitMachineLine(String line) {
    const expectedSegments = 8;
    final segments = <String>[];
    var buffer = line;

    for (var i = 0; i < expectedSegments - 1; i++) {
      final index = buffer.indexOf('|');
      if (index == -1) {
        return null;
      }
      segments.add(buffer.substring(0, index));
      buffer = buffer.substring(index + 1);
    }

    segments.add(buffer);
    if (segments.length != expectedSegments) {
      return null;
    }
    return segments;
  }

  String _coerceToString(Object? value) {
    if (value is String) {
      return value;
    }
    if (value is List<int>) {
      return utf8.decode(value);
    }
    return value?.toString() ?? '';
  }
}

class AnalyzerReport {
  const AnalyzerReport({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.issues,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
  final List<AnalyzerIssue> issues;

  bool get hasIssues => issues.isNotEmpty;
}

enum AnalyzerSeverity {
  error,
  warning,
  info,
  hint,
  other
  ;

  static AnalyzerSeverity fromLabel(String label) {
    switch (label.toUpperCase()) {
      case 'ERROR':
        return AnalyzerSeverity.error;
      case 'WARNING':
        return AnalyzerSeverity.warning;
      case 'INFO':
        return AnalyzerSeverity.info;
      case 'HINT':
        return AnalyzerSeverity.hint;
      default:
        return AnalyzerSeverity.other;
    }
  }

  bool get isActionable => this == AnalyzerSeverity.error || this == AnalyzerSeverity.warning;

  String get label => name.toUpperCase();
}

class AnalyzerIssue {
  const AnalyzerIssue({
    required this.severity,
    required this.code,
    required this.filePath,
    required this.line,
    required this.column,
    required this.length,
    required this.message,
  });

  final AnalyzerSeverity severity;
  final String code;
  final String filePath;
  final int line;
  final int column;
  final int length;
  final String message;

  bool get isActionable => severity.isActionable;

  String get severityLabel => severity.label;

  String relativePath(String workspaceRoot) {
    final normalizedFile = p.normalize(filePath);
    final normalizedRoot = p.normalize(workspaceRoot);
    if (normalizedFile == normalizedRoot) {
      return '.';
    }
    if (normalizedFile.startsWith('$normalizedRoot${p.separator}')) {
      return normalizedFile.substring(normalizedRoot.length + 1);
    }
    return normalizedFile;
  }
}
