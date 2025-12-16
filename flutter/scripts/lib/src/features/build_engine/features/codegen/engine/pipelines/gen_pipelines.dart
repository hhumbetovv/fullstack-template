import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/pipelines/gen/gen_context.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/gen/module_selector.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/gen/worker_config.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/gen/workflows/build_runner_workflow.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/gen/workflows/clean_queue.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/gen/workflows/watch_runner.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/stages/gen/prebuild_stage.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/stages/gen/run_build_stage.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/stages/gen/run_clean_stage.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/stages/gen/run_watch_stage.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/stages/gen/select_build_modules_stage.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/stages/gen/select_clean_modules_stage.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/stages/gen/select_watch_modules_stage.dart';

class GenBuildPipeline {
  GenBuildPipeline({
    required ModuleSelector selector,
    required BuildRunnerWorkflow workflow,
  })  : _selectStage = SelectBuildModulesStage(selector),
        _runStage = RunBuildStage(workflow);

  final SelectBuildModulesStage _selectStage;
  final RunBuildStage _runStage;

  Future<int> run(Iterable<String> filters) async {
    final context = await StageRunner<GenBuildContext>(
      stages: <Stage<GenBuildContext>>[
        _selectStage,
        _runStage,
      ],
    ).run(GenBuildContext(filters: filters));
    return context.exitCode;
  }
}

class GenCleanPipeline {
  GenCleanPipeline({
    required ModuleSelector selector,
    required WorkerConfig workerConfig,
    required CleanQueueWorkflow workflow,
  })  : _selectStage = SelectCleanModulesStage(selector),
        _runStage = RunCleanStage(workerConfig, workflow);

  final SelectCleanModulesStage _selectStage;
  final RunCleanStage _runStage;

  Future<int> run(String workerOption) async {
    final context = await StageRunner<GenCleanContext>(
      stages: <Stage<GenCleanContext>>[
        _selectStage,
        _runStage,
      ],
    ).run(GenCleanContext(workerOption: workerOption));
    return context.exitCode;
  }
}

class GenWatchPipeline {
  GenWatchPipeline({
    required ModuleSelector selector,
    required WatchRunnerWorkflow workflow,
    required SmartBuildRunner smartBuildRunner,
  })  : _selectStage = SelectWatchModulesStage(selector),
        _prebuildStage = PrebuildStage(smartBuildRunner),
        _runStage = RunWatchStage(workflow);

  final SelectWatchModulesStage _selectStage;
  final PrebuildStage _prebuildStage;
  final RunWatchStage _runStage;

  Future<int> run({
    required bool preBuild,
    required Iterable<String> filters,
  }) async {
    final context = await StageRunner<GenWatchContext>(
      stages: <Stage<GenWatchContext>>[
        _selectStage,
        _prebuildStage,
        _runStage,
      ],
    ).run(
      GenWatchContext(
        filters: filters,
        preBuild: preBuild,
      ),
    );
    return context.exitCode;
  }
}
