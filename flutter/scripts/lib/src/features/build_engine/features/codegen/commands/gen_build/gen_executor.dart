import 'package:scripts/src/features/build_engine/domain/ports/module_discovery_port.dart';
import 'package:scripts/src/features/build_engine/features/codegen/domain/models/smart_build_options.dart';
import 'package:scripts/src/features/build_engine/features/codegen/domain/ports/build_runner_port.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/pipelines/gen_pipelines.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/gen/module_selector.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/gen/worker_config.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/gen/workflows/build_runner_workflow.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/gen/workflows/clean_queue.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/gen/workflows/watch_runner.dart';

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
    return GenBuildPipeline(
      selector: _moduleSelector,
      workflow: _buildWorkflow,
    ).run(filters);
  }

  Future<int> runClean(String workerOption) async {
    return GenCleanPipeline(
      selector: _moduleSelector,
      workerConfig: _workerConfig,
      workflow: _cleanWorkflow,
    ).run(workerOption);
  }

  Future<int> runWatch({
    required bool preBuild,
    required Iterable<String> filters,
  }) async {
    return GenWatchPipeline(
      selector: _moduleSelector,
      workflow: _watchWorkflow,
      smartBuildRunner: _smartBuildRunner,
    ).run(preBuild: preBuild, filters: filters);
  }
}
