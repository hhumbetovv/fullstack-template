import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;

import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/services/build_runner_service.dart';
import 'package:scripts/src/services/workspace_service.dart';

Future<int> runGenCleanFeature(String workerOption) async {
  final modules = await discoverModules(includeNonBuildRunner: false);
  if (modules.isEmpty) {
    Console.warning('No modules with build_runner were found.');
    return 0;
  }

  final workers = _resolveWorkerCount(workerOption, modules.length);

  Console.write('🚀 Cleaning generated files (workers: $workers)');

  final failures = <ModuleInfo>[];
  final queue = Queue<ModuleInfo>.from(modules);
  final tasks = <Future<void>>[];

  for (var index = 0; index < workers; index++) {
    if (queue.isEmpty) break;
    tasks.add(_runWorker(index, workers, queue, failures));
  }

  await Future.wait(tasks);

  Console.write('\n🧹 Removing generated artifacts');
  deleteGeneratedArtifacts();

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
  Queue<ModuleInfo> queue,
  List<ModuleInfo> failures,
) async {
  while (true) {
    ModuleInfo? module;
    if (queue.isEmpty) {
      return;
    }
    module = queue.removeFirst();

    Console.write('🧹 [${index + 1}/$totalWorkers] ${module.path}');

    final result = await runBuildRunnerCommand(
      module.directory,
      ['clean'],
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

int _resolveWorkerCount(String? raw, int moduleCount) {
  if (moduleCount <= 1) return 1;

  final value = raw?.trim();
  if (value == null || value.isEmpty || value.toLowerCase() == 'auto') {
    final processors = Platform.numberOfProcessors;
    final suggested = processors > 2 ? processors ~/ 2 : processors;
    return math.max(1, math.min(suggested, moduleCount));
  }

  final parsed = int.tryParse(value);
  if (parsed == null || parsed <= 0) {
    return 1;
  }

  return math.max(1, math.min(parsed, moduleCount));
}
