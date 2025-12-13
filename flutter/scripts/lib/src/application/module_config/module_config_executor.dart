import 'dart:io';

import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/domain/models/module_config.dart';
import 'package:scripts/src/infrastructure/module_config/module_config_service.dart';

class ModuleConfigExecutor {
  ModuleConfigExecutor({required ModuleConfigService service})
    : _service = service;

  final ModuleConfigService _service;

  Future<int> run({required ModuleSyncOptions options}) async {
    Console.write('=====================================');
    final headline = options.reverse
        ? '    Module module.yaml sync'
        : '    Module pubspec sync';
    Console.write(headline);
    Console.write('=====================================');

    final summary = await _service.syncModules(options: options);

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
      Console.error('Module sync finished with errors.');
      return 1;
    }

    if (summary.checkMode && summary.hasChanges) {
      Console.error(
        'Pubspecs are out of sync. Run without --check to apply fixes.',
      );
      return 1;
    }

    if (_shouldRunPubGet(options, summary)) {
      try {
        await _runPubGet(summary.pubspecChanges);
      } on CommandError catch (error) {
        _revertPubspecChanges(summary.pubspecChanges);
        _revertBuildChanges(summary.buildChanges);
        Console.error(
          'flutter pub get failed: ${error.message}. Changes have been reverted.',
        );
        return 1;
      } on ProcessException catch (error) {
        _revertPubspecChanges(summary.pubspecChanges);
        _revertBuildChanges(summary.buildChanges);
        Console.error(
          'Failed to start flutter pub get (${error.message}). Changes have been reverted.',
        );
        return 1;
      }
    }

    Console.success('Module sync completed successfully.');
    return 0;
  }

  bool _shouldRunPubGet(ModuleSyncOptions options, ModuleSyncSummary summary) {
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
