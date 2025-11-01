import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;

import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/feature/smart_build/command/options.dart';
import 'package:scripts/src/services/build_runner_service.dart';
import 'package:scripts/src/services/workspace_service.dart';

typedef SmartBuildRunner = Future<int> Function(SmartBuildOptions options);

class GenFeature {
  GenFeature({
    required WorkspaceService workspaceService,
    required BuildRunnerService buildRunnerService,
    required SmartBuildRunner smartBuildRunner,
  }) : _workspaceService = workspaceService,
       _buildRunnerService = buildRunnerService,
       _smartBuildRunner = smartBuildRunner;

  final WorkspaceService _workspaceService;
  final BuildRunnerService _buildRunnerService;
  final SmartBuildRunner _smartBuildRunner;

  Future<int> runBuild(Iterable<String> moduleFilters) async {
    final modules = await _workspaceService.discoverModules(
      includeNonBuildRunner: true,
    );
    if (modules.isEmpty) {
      Console.error('No modules discovered. Are you in the repository root?');
      return 1;
    }

    final targets = <ModuleInfo>[];

    if (moduleFilters.isEmpty) {
      targets.addAll(modules.where((module) => module.hasBuildRunner));
      Console.info('Building all modules with build_runner...');
    } else {
      Console.info('Building selected modules: ${moduleFilters.join(', ')}');
      for (final filter in moduleFilters) {
        final module = _workspaceService.findModule(modules, filter);
        if (module == null) {
          Console.warning(
            "Module '$filter' not found by name or path, skipping...",
          );
          continue;
        }
        if (!module.hasBuildRunner) {
          Console.warning(
            "Module '${module.name}' does not depend on build_runner, skipping...",
          );
          continue;
        }
        targets.add(module);
      }
    }

    if (targets.isEmpty) {
      Console.warning('No matching modules to build.');
      return 0;
    }

    var hasFailures = false;

    for (final module in targets) {
      Console.write('\n🔨 Building ${module.name} (${module.path})');
      final result = await _buildRunnerService.runCommand(
        module.directory,
        const ['build', '-d'],
      );
      if (result.exitCode == 0) {
        Console.success('✅ Build complete for ${module.name}');
      } else {
        hasFailures = true;
        Console.error('❌ Build failed for ${module.name}');
      }
    }

    Console.write('\n🎉 Build process completed!');
    return hasFailures ? 1 : 0;
  }

  Future<int> runClean(String workerOption) async {
    final modules = await _workspaceService.discoverModules(
      includeNonBuildRunner: false,
    );
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
      tasks.add(_runCleanWorker(index, workers, queue, failures));
    }

    await Future.wait(tasks);

    Console.write('\n🧹 Removing generated artifacts');
    _buildRunnerService.deleteGeneratedArtifacts();

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

  Future<int> runWatch({
    required bool preBuild,
    required Iterable<String> filters,
  }) async {
    final modules = await _workspaceService.discoverModules(
      includeNonBuildRunner: false,
    );
    if (modules.isEmpty) {
      Console.warning('No modules with build_runner were found.');
      return 0;
    }

    final targets = <ModuleInfo>[];
    if (filters.isEmpty) {
      targets.addAll(modules);
    } else {
      for (final value in filters) {
        final module = _workspaceService.findModule(modules, value);
        if (module == null) {
          Console.warning("Module '$value' not found, skipping...");
          continue;
        }
        targets.add(module);
      }
    }

    if (targets.isEmpty) {
      Console.warning('No matching modules to watch.');
      return 0;
    }

    if (preBuild) {
      Console.info('Running smart-build before starting watchers...');
      final exitCode = await _smartBuildRunner(
        const SmartBuildOptions(
          verbose: false,
          dryRun: false,
          maxParallelBuilds: 4,
        ),
      );
      if (exitCode != 0) {
        Console.error(
          'smart-build failed (exit code $exitCode). Continuing watchers.',
        );
      }
    }

    Console.write('🚀 Starting watch mode...');

    final processes = <Process>[];
    final completers = <Completer<void>>[];

    for (final module in targets) {
      Console.write('👀 ${module.path} (${module.name})');
      final process = await _buildRunnerService.startWatch(
        module.directory,
        const ['-d'],
      );
      processes.add(process);
      final completer = Completer<void>();
      completers.add(completer);
      unawaited(
        process.exitCode.then((code) {
          if (code != 0) {
            Console.error('Watcher for ${module.name} exited with code $code');
          }
          completer.complete();
        }),
      );
    }

    void cleanup() {
      unawaited(_buildRunnerService.cancelProcesses(processes));
    }

    final subscriptions = <StreamSubscription<ProcessSignal>>[
      ProcessSignal.sigint.watch().listen((_) {
        Console.warning('Stopping watchers...');
        cleanup();
      }),
      ProcessSignal.sigterm.watch().listen((_) {
        Console.warning('Stopping watchers...');
        cleanup();
      }),
    ];

    await Future.wait(completers.map((c) => c.future));

    for (final subscription in subscriptions) {
      await subscription.cancel();
    }

    Console.success('Watchers stopped.');
    return 0;
  }

  Future<void> _runCleanWorker(
    int index,
    int totalWorkers,
    Queue<ModuleInfo> queue,
    List<ModuleInfo> failures,
  ) async {
    while (queue.isNotEmpty) {
      final module = queue.removeFirst();

      Console.write('🧹 [${index + 1}/$totalWorkers] ${module.path}');

      final result = await _buildRunnerService.runCommand(
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
}
