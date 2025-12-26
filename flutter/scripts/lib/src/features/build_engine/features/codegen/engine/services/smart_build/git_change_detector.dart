import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/smart_build/build_log_reader.dart';

class GitChangeDetector {
  const GitChangeDetector();

  Future<Set<String>> findModulesWithChanges({
    required Map<String, String> modulePaths,
    required Map<String, BuildLogEntry> logMetadata,
  }) async {
    final changed = <String>{};
    for (final entry in modulePaths.entries) {
      final moduleName = entry.key;
      final modulePath = entry.value;
      final lastBuild = logMetadata[moduleName]?.startedAt;
      final hasChanges = await _hasGitChanges(modulePath, lastBuild);
      if (hasChanges) {
        changed.add(moduleName);
      }
    }
    return changed;
  }

  Future<bool> _hasGitChanges(String modulePath, DateTime? lastBuild) async {
    final normalizedModulePath = _normalizePath(modulePath);
    final args = <String>['log', '-1', '--pretty=format:%ct'];
    if (lastBuild != null) {
      args.add('--since=${lastBuild.toUtc().toIso8601String()}');
    }
    args
      ..add('--')
      ..add(normalizedModulePath);

    final result = await Process.run(
      'git',
      args,
      workingDirectory: Directory.current.path,
    );

    if (result.exitCode != 0) {
      final stderr = (result.stderr is String)
          ? (result.stderr as String).trim()
          : result.stderr.toString().trim();
      final suffix = stderr.isEmpty ? '' : ': $stderr';
      Logger.debug('git log failed for $normalizedModulePath$suffix');
      return true;
    }

    final output = (result.stdout as String).trim();
    if (output.isEmpty) {
      return lastBuild == null;
    }

    if (lastBuild == null) {
      return true;
    }

    final timestamp = int.tryParse(output.split('\n').last.trim());
    if (timestamp == null) {
      return true;
    }
    final commitTime = DateTime.fromMillisecondsSinceEpoch(
      timestamp * 1000,
      isUtc: true,
    );
    return commitTime.isAfter(lastBuild.toUtc());
  }

  String _normalizePath(String rawPath) {
    final normalized = p.normalize(rawPath);
    if (normalized.startsWith('./')) {
      return normalized.substring(2);
    }
    return normalized;
  }
}
