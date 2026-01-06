import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scripts/src/core/logging/logging.dart';

class BuildLogMetadataReader {
  const BuildLogMetadataReader();

  static final RegExp _logNamePattern = RegExp(r'^build_(.+)\.log$');
  static final RegExp _startPattern = RegExp('=== Build started at (.+?) ===');
  static final RegExp _finishPattern = RegExp('=== Build finished at (.+?) ===');
  static final RegExp _gitHeadPattern = RegExp('=== Git head: (.+?) ===');
  static final RegExp _statusPattern = RegExp(
    '=== Build status: (success|failure) ===',
  );

  Future<Map<String, BuildLogEntry>> read(String logsDirectory) async {
    final directory = Directory(logsDirectory);
    if (!directory.existsSync()) {
      return <String, BuildLogEntry>{};
    }

    final entries = <String, BuildLogEntry>{};
    for (final entity in directory.listSync(recursive: false)) {
      if (entity is! File) {
        continue;
      }
      final moduleName = _extractModuleName(entity.path);
      if (moduleName == null) {
        continue;
      }
      try {
        entries[moduleName] = await _parseLog(entity);
      } on Object catch (error) {
        Logger.debug('Failed to parse build log for $moduleName: $error');
      }
    }

    return entries;
  }

  String? _extractModuleName(String filePath) {
    final basename = p.basename(filePath);
    final match = _logNamePattern.firstMatch(basename);
    return match?.group(1);
  }

  Future<BuildLogEntry> _parseLog(File file) async {
    final content = await file.readAsString();
    final startedAt = _parseStart(content);
    final finishedAt = _parseFinish(content);
    final gitHead = _parseGitHead(content);
    final succeeded = _parseStatus(content);
    return BuildLogEntry(
      path: file.path,
      startedAt: startedAt,
      finishedAt: finishedAt,
      gitHead: gitHead,
      succeeded: succeeded,
    );
  }

  DateTime? _parseStart(String content) {
    final startMatch = _startPattern.firstMatch(content);
    final raw = startMatch?.group(1)?.trim();
    if (raw == null) {
      return null;
    }
    try {
      return DateTime.parse(raw);
    } on Object {
      return null;
    }
  }

  bool? _parseStatus(String content) {
    final statusMatch = _statusPattern.firstMatch(content);
    final marker = statusMatch?.group(1)?.toLowerCase();
    if (marker == 'success') {
      return true;
    }
    if (marker == 'failure') {
      return false;
    }

    if (content.contains('Built with build_runner in')) {
      return true;
    }
    if (content.contains('Failed after') ||
        content.contains('Unhandled exception')) {
      return false;
    }
    return null;
  }

  String? _parseGitHead(String content) {
    final match = _gitHeadPattern.firstMatch(content);
    final raw = match?.group(1)?.trim();
    if (raw == null || raw.isEmpty || raw == 'unknown') {
      return null;
    }
    return raw;
  }

  DateTime? _parseFinish(String content) {
    final finishMatch = _finishPattern.firstMatch(content);
    final raw = finishMatch?.group(1)?.trim();
    if (raw == null) {
      return null;
    }
    try {
      return DateTime.parse(raw);
    } on Object {
      return null;
    }
  }
}

class BuildLogEntry {
  const BuildLogEntry({
    required this.path,
    this.startedAt,
    this.finishedAt,
    this.gitHead,
    this.succeeded,
  });

  final String path;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String? gitHead;
  final bool? succeeded;
}
