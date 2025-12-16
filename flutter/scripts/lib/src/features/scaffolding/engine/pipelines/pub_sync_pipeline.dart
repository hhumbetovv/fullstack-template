import 'dart:io';

import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/scaffolding/domain/adapters/module_config_service.dart';
import 'package:scripts/src/features/scaffolding/domain/models/module_config.dart';

class PubSyncContext {
  PubSyncContext({required this.options});

  final ModuleSyncOptions options;
  ModuleSyncSummary? summary;
  int exitCode = 0;
}

class PubSyncPipeline {
  PubSyncPipeline({
    required ModuleConfigService service,
  })  : _syncStage = _SyncModulesStage(service),
        _summaryStage = _SummaryStage(),
        _pubGetStage = _PubGetStage();

  final _SyncModulesStage _syncStage;
  final _SummaryStage _summaryStage;
  final _PubGetStage _pubGetStage;

  Future<PubSyncContext> run(PubSyncContext context) {
    return StageRunner<PubSyncContext>(
      stages: <Stage<PubSyncContext>>[
        _syncStage,
        _summaryStage,
        _pubGetStage,
      ],
    ).run(context);
  }
}

class _SyncModulesStage implements Stage<PubSyncContext> {
  _SyncModulesStage(this._service);

  final ModuleConfigService _service;

  @override
  String get name => 'sync-modules';

  @override
  Future<PubSyncContext> run(PubSyncContext context) async {
    context.summary = await _service.syncModules(options: context.options);
    return context;
  }
}

class _SummaryStage implements Stage<PubSyncContext> {
  @override
  String get name => 'summarize';

  @override
  Future<PubSyncContext> run(PubSyncContext context) async {
    final summary = context.summary;
    if (summary == null) {
      throw const CommandError('Missing summary after sync stage.');
    }

    Console.write('=====================================');
    final headline = context.options.reverse
        ? '    Module module.yaml sync'
        : '    Module pubspec sync';
    Console.write(headline);
    Console.write('=====================================');

    if (summary.changed.isNotEmpty) {
      final pubspecModules = summary.pubspecChanges
          .map((change) => change.moduleName)
          .toSet();
      final buildModules = summary.buildChanges
          .map((change) => change.moduleName)
          .toSet();
      for (final module in summary.changed) {
        final prefix = summary.checkMode ? 'Would update' : 'Updated';
        final changes = <String>[];
        if (pubspecModules.contains(module)) {
          changes.add('pubspec');
        }
        if (buildModules.contains(module)) {
          changes.add('build.yaml');
        }
        final suffix = changes.isEmpty ? '' : ' (${changes.join(' + ')})';
        Console.success('✓ $prefix $module$suffix');
      }
    } else {
      Console.warning(
        summary.checkMode
            ? 'No pubspec changes detected.'
            : 'No modules needed updates.',
      );
    }

    if (summary.formatted.isNotEmpty) {
      for (final module in summary.formatted) {
        Console.info('Formatted module.yaml for $module');
      }
    }

    if (summary.lockFilePath != null) {
      Console.info('Wrote ${summary.lockFilePath}');
    }

    if (summary.reportFilePath != null) {
      Console.info('Wrote ${summary.reportFilePath}');
    }

    if (summary.workspaceConfigPath != null) {
      final prefix = summary.checkMode ? 'Would write' : 'Wrote';
      Console.info('$prefix ${summary.workspaceConfigPath}');
    }

    if (summary.failures.isNotEmpty) {
      Console.write('\nFailures:');
      summary.failures.forEach((module, message) {
        Console.error('✗ $module – $message');
      });
    }

    Console.write('=====================================');

    if (summary.hasFailures) {
      context.exitCode = 1;
      return context;
    }

    if (summary.checkMode && summary.hasChanges) {
      context.exitCode = 1;
      return context;
    }

    context.exitCode = 0;
    return context;
  }
}

class _PubGetStage implements Stage<PubSyncContext> {
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
        '`flutter pub get` failed at the workspace root',
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
