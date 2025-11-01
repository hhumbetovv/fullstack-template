import 'dart:async';
import 'dart:collection';

import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/domain/models/module_descriptor.dart';
import 'package:scripts/src/domain/ports/build_runner_port.dart';

class CleanQueueWorkflow {
  CleanQueueWorkflow(this._buildRunner);

  final BuildRunnerPort _buildRunner;

  Future<int> execute({
    required int workerCount,
    required List<ModuleDescriptor> modules,
  }) async {
    if (modules.isEmpty) {
      Console.warning('No modules with build_runner were found.');
      return 0;
    }

    Console.write('🚀 Cleaning generated files (workers: $workerCount)');

    final failures = <ModuleDescriptor>[];
    final queue = Queue<ModuleDescriptor>.from(modules);
    final tasks = <Future<void>>[];

    for (var index = 0; index < workerCount; index++) {
      if (queue.isEmpty) break;
      tasks.add(_runWorker(index, workerCount, queue, failures));
    }

    await Future.wait(tasks);

    Console.write('\n🧹 Removing generated artifacts');
    _buildRunner.deleteGeneratedArtifacts();

    if (failures.isNotEmpty) {
      Console.error('Some clean steps failed:');
      for (final module in failures) {
        Console.error(' - ${module.name} (${module.path})');
      }
      return 1;
    }

    Console.success('✅ All cleanups completed');
    return 0;
  }

  Future<void> _runWorker(
    int index,
    int totalWorkers,
    Queue<ModuleDescriptor> queue,
    List<ModuleDescriptor> failures,
  ) async {
    while (queue.isNotEmpty) {
      final module = queue.removeFirst();

      Console.write('🧹 [${index + 1}/$totalWorkers] ${module.path}');

      final result = await _buildRunner.runCommand(
        module.directory,
        const ['clean'],
        forwardOutput: false,
      );

      if (result.exitCode == 0) {
        Console.success('✅ Cleaned ${module.name}');
      } else {
        failures.add(module);
        Console.error('❌ Failed to clean ${module.name}');

        final stderr = result.stderr?.toString().trim();
        if (stderr != null && stderr.isNotEmpty) {
          Console.error(stderr);
        }
        final stdout = result.stdout?.toString().trim();
        if (stdout != null && stdout.isNotEmpty) {
          Console.write(stdout);
        }
      }
    }
  }
}
