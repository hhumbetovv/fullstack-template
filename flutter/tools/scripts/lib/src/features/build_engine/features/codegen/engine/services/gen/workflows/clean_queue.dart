import 'dart:async';
import 'dart:collection';

import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/features/build_engine/domain/models/module_descriptor.dart';
import 'package:scripts/src/features/build_engine/features/codegen/domain/ports/build_runner_port.dart';

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

    final orderedModules = [...modules]
      ..sort((a, b) => a.name.compareTo(b.name));
    final totalModules = orderedModules.length;

    Console.info(
      '🚀 Cleaning $totalModules modules using $workerCount worker(s)...',
    );

    final tracker = _ProgressTracker(totalModules);
    final failures = <ModuleDescriptor>[];
    final queue = Queue<ModuleDescriptor>.from(orderedModules);
    final tasks = <Future<void>>[];

    for (var index = 0; index < workerCount; index++) {
      if (queue.isEmpty) break;
      tasks.add(
        _runWorker(
          index,
          workerCount,
          queue,
          failures,
          tracker,
        ),
      );
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
    _ProgressTracker tracker,
  ) async {
    while (queue.isNotEmpty) {
      final module = queue.removeFirst();
      Console.info(
        '🧹 Worker ${index + 1}/$totalWorkers cleaning ${module.name}',
      );

      final result = await _buildRunner.runCommand(
        module.directory,
        const ['clean'],
        forwardOutput: false,
      );

      final label = tracker.advance();
      if (result.exitCode == 0) {
        Console.success('✅ [$label] ${module.name}');
      } else {
        failures.add(module);
        Console.error('❌ [$label] Failed to clean ${module.name}');

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

class _ProgressTracker {
  _ProgressTracker(this.total);

  final int total;
  int _completed = 0;

  String advance() {
    _completed++;
    return '$_completed/$total';
  }
}
