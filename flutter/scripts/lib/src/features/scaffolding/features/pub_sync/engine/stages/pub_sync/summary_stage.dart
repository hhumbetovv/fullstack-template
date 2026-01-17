import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/scaffolding/features/pub_sync/engine/pipelines/pub_sync/pub_sync_context.dart';

class SummaryStage implements Stage<PubSyncContext> {
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
      final pubspecModules = summary.pubspecChanges.map((change) => change.moduleName).toSet();
      final buildModules = summary.buildChanges.map((change) => change.moduleName).toSet();
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
