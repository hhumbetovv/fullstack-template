import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/build_engine/domain/models/module_descriptor.dart';
import 'package:scripts/src/features/build_engine/features/codegen/commands/gen_build/gen_executor.dart';
import 'package:scripts/src/features/build_engine/features/codegen/domain/models/smart_build_options.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/gen/module_selector.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/gen/worker_config.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/gen/workflows/build_runner_workflow.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/gen/workflows/clean_queue.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/gen/workflows/watch_runner.dart';

class GenBuildContext {
  GenBuildContext({required this.filters});

  final Iterable<String> filters;
  List<ModuleDescriptor> modules = const [];
  int exitCode = 0;
}

class GenCleanContext {
  GenCleanContext({
    required this.workerOption,
  });

  final String workerOption;
  List<ModuleDescriptor> modules = const [];
  int workerCount = 1;
  int exitCode = 0;
}

class GenWatchContext {
  GenWatchContext({
    required this.filters,
    required this.preBuild,
  });

  final Iterable<String> filters;
  final bool preBuild;
  List<ModuleDescriptor> modules = const [];
  int exitCode = 0;
}

class GenBuildPipeline {
  GenBuildPipeline({
    required ModuleSelector selector,
    required BuildRunnerWorkflow workflow,
  })  : _selectStage = _SelectBuildModulesStage(selector),
        _runStage = _RunBuildStage(workflow);

  final _SelectBuildModulesStage _selectStage;
  final _RunBuildStage _runStage;

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
  })  : _selectStage = _SelectCleanModulesStage(selector),
        _runStage = _RunCleanStage(workerConfig, workflow);

  final _SelectCleanModulesStage _selectStage;
  final _RunCleanStage _runStage;

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
  })  : _selectStage = _SelectWatchModulesStage(selector),
        _prebuildStage = _PrebuildStage(smartBuildRunner),
        _runStage = _RunWatchStage(workflow);

  final _SelectWatchModulesStage _selectStage;
  final _PrebuildStage _prebuildStage;
  final _RunWatchStage _runStage;

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

class _SelectBuildModulesStage implements Stage<GenBuildContext> {
  _SelectBuildModulesStage(this._selector);

  final ModuleSelector _selector;

  @override
  String get name => 'select-build-modules';

  @override
  Future<GenBuildContext> run(GenBuildContext context) async {
    final modules = await _selector.selectForBuild(context.filters);
    context
      ..modules = modules
      ..exitCode = modules.isEmpty ? (context.filters.isEmpty ? 1 : 0) : 0;
    return context;
  }
}

class _RunBuildStage implements Stage<GenBuildContext> {
  _RunBuildStage(this._workflow);

  final BuildRunnerWorkflow _workflow;

  @override
  String get name => 'run-build';

  @override
  Future<GenBuildContext> run(GenBuildContext context) async {
    if (context.modules.isEmpty) {
      return context;
    }
    context.exitCode = await _workflow.execute(context.modules);
    return context;
  }
}

class _SelectCleanModulesStage implements Stage<GenCleanContext> {
  _SelectCleanModulesStage(this._selector);

  final ModuleSelector _selector;

  @override
  String get name => 'select-clean-modules';

  @override
  Future<GenCleanContext> run(GenCleanContext context) async {
    final modules = await _selector.selectForClean();
    context.modules = modules;
    return context;
  }
}

class _RunCleanStage implements Stage<GenCleanContext> {
  _RunCleanStage(this._workerConfig, this._workflow);

  final WorkerConfig _workerConfig;
  final CleanQueueWorkflow _workflow;

  @override
  String get name => 'run-clean';

  @override
  Future<GenCleanContext> run(GenCleanContext context) async {
    if (context.modules.isEmpty) {
      context.exitCode = 0;
      return context;
    }
    context
      ..workerCount = _workerConfig.resolve(
        context.workerOption,
        context.modules.length,
      )
      ..exitCode = await _workflow.execute(
        workerCount: context.workerCount,
        modules: context.modules,
      );
    return context;
  }
}

class _SelectWatchModulesStage implements Stage<GenWatchContext> {
  _SelectWatchModulesStage(this._selector);

  final ModuleSelector _selector;

  @override
  String get name => 'select-watch-modules';

  @override
  Future<GenWatchContext> run(GenWatchContext context) async {
    final modules = await _selector.selectForWatch(context.filters);
    context
      ..modules = modules
      ..exitCode = modules.isEmpty ? 0 : context.exitCode;
    return context;
  }
}

class _PrebuildStage implements Stage<GenWatchContext> {
  _PrebuildStage(this._smartBuildRunner);

  final SmartBuildRunner _smartBuildRunner;

  @override
  String get name => 'pre-build';

  @override
  Future<GenWatchContext> run(GenWatchContext context) async {
    if (!context.preBuild || context.modules.isEmpty) {
      return context;
    }
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
    return context;
  }
}

class _RunWatchStage implements Stage<GenWatchContext> {
  _RunWatchStage(this._workflow);

  final WatchRunnerWorkflow _workflow;

  @override
  String get name => 'run-watch';

  @override
  Future<GenWatchContext> run(GenWatchContext context) async {
    if (context.modules.isEmpty) {
      context.exitCode = 0;
      return context;
    }
    context.exitCode = await _workflow.execute(context.modules);
    return context;
  }
}
