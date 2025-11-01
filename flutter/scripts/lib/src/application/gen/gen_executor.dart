import 'package:scripts/src/application/gen/helpers/module_selector.dart';
import 'package:scripts/src/application/gen/helpers/worker_config.dart';
import 'package:scripts/src/application/gen/workflows/build_runner_workflow.dart';
import 'package:scripts/src/application/gen/workflows/clean_queue.dart';
import 'package:scripts/src/application/gen/workflows/watch_runner.dart';
import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/domain/models/smart_build_options.dart';
import 'package:scripts/src/domain/ports/build_runner_port.dart';
import 'package:scripts/src/domain/ports/module_discovery_port.dart';

typedef SmartBuildRunner = Future<int> Function(SmartBuildOptions options);

class GenExecutor {
  GenExecutor({
    required ModuleDiscoveryPort moduleDiscovery,
    required BuildRunnerPort buildRunner,
    required SmartBuildRunner smartBuildRunner,
  }) : _moduleSelector = ModuleSelector(moduleDiscovery),
       _buildWorkflow = BuildRunnerWorkflow(buildRunner),
       _cleanWorkflow = CleanQueueWorkflow(buildRunner),
       _watchWorkflow = WatchRunnerWorkflow(buildRunner),
       _workerConfig = const WorkerConfig(),
       _smartBuildRunner = smartBuildRunner;

  final ModuleSelector _moduleSelector;
  final BuildRunnerWorkflow _buildWorkflow;
  final CleanQueueWorkflow _cleanWorkflow;
  final WatchRunnerWorkflow _watchWorkflow;
  final WorkerConfig _workerConfig;
  final SmartBuildRunner _smartBuildRunner;

  Future<int> runBuild(Iterable<String> filters) async {
    final targets = await _moduleSelector.selectForBuild(filters);
    if (targets.isEmpty) {
      return filters.isEmpty ? 1 : 0;
    }
    return _buildWorkflow.execute(targets);
  }

  Future<int> runClean(String workerOption) async {
    final modules = await _moduleSelector.selectForClean();
    if (modules.isEmpty) {
      Console.warning('No modules with build_runner were found.');
      return 0;
    }

    final workers = _workerConfig.resolve(workerOption, modules.length);
    return _cleanWorkflow.execute(workerCount: workers, modules: modules);
  }

  Future<int> runWatch({
    required bool preBuild,
    required Iterable<String> filters,
  }) async {
    final modules = await _moduleSelector.selectForWatch(filters);
    if (modules.isEmpty) {
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

    return _watchWorkflow.execute(modules);
  }
}
