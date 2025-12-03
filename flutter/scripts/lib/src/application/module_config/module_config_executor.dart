import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/domain/models/module_config.dart';
import 'package:scripts/src/infrastructure/module_config/module_config_service.dart';

class ModuleConfigExecutor {
  ModuleConfigExecutor({required ModuleConfigService service})
    : _service = service;

  final ModuleConfigService _service;

  Future<int> run({required ModuleSyncOptions options}) async {
    Console.write('=====================================');
    Console.write('    Module pubspec sync');
    Console.write('=====================================');

    final summary = await _service.syncModules(options: options);

    if (summary.changed.isNotEmpty) {
      for (final module in summary.changed) {
        final prefix = summary.checkMode ? 'Would update' : 'Updated';
        Console.success('✓ $prefix $module');
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

    Console.success('Module sync completed successfully.');
    return 0;
  }
}
