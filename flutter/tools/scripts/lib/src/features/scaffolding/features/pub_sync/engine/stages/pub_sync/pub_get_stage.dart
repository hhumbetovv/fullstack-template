import 'dart:io';

import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/scaffolding/domain/models/module_config.dart';
import 'package:scripts/src/features/scaffolding/features/pub_sync/engine/pipelines/pub_sync/pub_sync_context.dart';

class PubGetStage implements Stage<PubSyncContext> {
  @override
  String get name => 'pub-get';

  @override
  Future<PubSyncContext> run(PubSyncContext context) async {
    final summary = context.summary;
    if (summary == null) {
      throw const CommandError('Missing summary before pub get stage.');
    }

    if (_shouldRunPubGet(context.options, summary)) {
      try {
        await _runPubGet(summary.pubspecChanges);
      } on CommandError catch (error) {
        _revertPubspecChanges(summary.pubspecChanges);
        _revertBuildChanges(summary.buildChanges);
        Console.error(
          'flutter pub get failed: ${error.message}. Changes have been reverted.',
        );
        context.exitCode = 1;
      } on ProcessException catch (error) {
        _revertPubspecChanges(summary.pubspecChanges);
        _revertBuildChanges(summary.buildChanges);
        Console.error(
          'Failed to start flutter pub get (${error.message}). Changes have been reverted.',
        );
        context.exitCode = 1;
      }
    }

    return context;
  }

  bool _shouldRunPubGet(
    ModuleSyncOptions options,
    ModuleSyncSummary summary,
  ) {
    return !options.checkOnly &&
        !summary.hasFailures &&
        summary.pubspecChanges.isNotEmpty;
  }

  Future<void> _runPubGet(List<ModulePubspecChange> modules) async {
    final moduleSummary = modules.length == 1
        ? modules.first.moduleName
        : '${modules.length} modules';
    Console.info(
      'Running flutter pub get at workspace root after updating $moduleSummary...',
    );
    final process = await Process.start(
      'fvm',
      const ['flutter', 'pub', 'get'],
      workingDirectory: Directory.current.path,
      mode: ProcessStartMode.inheritStdio,
    );
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw CommandError(
        'flutter pub get exited with code $exitCode',
        exitCode: exitCode,
      );
    }
  }

  void _revertPubspecChanges(List<ModulePubspecChange> modules) {
    for (final change in modules) {
      final file = File(change.pubspecPath);
      if (!change.hadExistingFile) {
        if (file.existsSync()) {
          file.deleteSync();
        }
        continue;
      }
      file
        ..createSync(recursive: true)
        ..writeAsStringSync(change.previousContent ?? '');
    }
  }

  void _revertBuildChanges(List<ModuleBuildChange> modules) {
    for (final change in modules) {
      final file = File(change.buildFilePath);
      if (!change.hadExistingFile) {
        if (file.existsSync()) {
          file.deleteSync();
        }
        continue;
      }
      file
        ..createSync(recursive: true)
        ..writeAsStringSync(change.previousContent ?? '');
    }
  }
}
