import 'dart:async';
import 'dart:io';

import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/build_engine/domain/models/build_plan.dart';
import 'package:scripts/src/features/build_engine/domain/models/build_state.dart';
import 'package:scripts/src/features/build_engine/domain/models/dependency_report.dart';
import 'package:scripts/src/features/build_engine/domain/models/graph_report.dart';
import 'package:scripts/src/features/build_engine/domain/ports/module_graph_port.dart';
import 'package:scripts/src/features/build_engine/engine/services/environment_service.dart';
import 'package:scripts/src/features/build_engine/engine/stages/analyze_dependencies_stage.dart';
import 'package:scripts/src/features/build_engine/engine/stages/build_plan_stage.dart';
import 'package:scripts/src/features/build_engine/engine/stages/discover_modules_stage.dart';
import 'package:scripts/src/features/build_engine/engine/stages/generate_graph_stage.dart';
import 'package:scripts/src/features/build_engine/engine/stages/validate_env_stage.dart';
import 'package:scripts/src/features/build_engine/features/codegen/commands/smart_build/smart_build_context.dart';
import 'package:scripts/src/features/build_engine/features/codegen/domain/models/smart_build_options.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/build_execution/build_execution_service.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/stages/retain_target_module_stage.dart';
import 'package:scripts/src/features/build_engine/utils/signal_utils.dart';

class SmartBuildExecutor {
  SmartBuildExecutor({
    required ModuleGraphPort moduleGraphPort,
    required EnvironmentService environmentService,
    required BuildExecutionService buildExecutionService,
  }) : _moduleGraphPort = moduleGraphPort,
       _environmentService = environmentService,
       _buildExecutionService = buildExecutionService;

  final ModuleGraphPort _moduleGraphPort;
  final EnvironmentService _environmentService;
  final BuildExecutionService _buildExecutionService;

  Future<int> run(SmartBuildOptions options) async {
    final store = BuildStateStore();
    final state = store.configure(
      verbose: options.verbose,
      dryRun: options.dryRun,
      maxParallelBuilds: options.maxParallelBuilds,
      targetModule: options.targetModule,
    );
    Logger.configure(LoggerConfig(verbose: options.verbose));

    final subscriptions = <StreamSubscription<ProcessSignal>>[];

    log('');
    Logger.info('🎯 Flutter Smart Build System v2.0 (Dart)');
    Logger.info('════════════════════════════════════════');
    log('');

    try {
      if (state.verbose) {
        Logger.debug('Configuration:');
        Logger.debug('   Verbose: ${state.verbose}');
        Logger.debug('   Dry Run: ${state.dryRun}');
        Logger.debug('   Max Parallel: ${state.maxParallelBuilds}');
        Logger.debug('   Target Module: ${state.targetModule ?? 'all'}');
        Logger.debug('   Working Directory: ${Directory.current.path}');
        log('');
      }

      final sigintSub = listenForSignal(
        ProcessSignal.sigint,
        (_) async {
          await _environmentService.cleanup(state);
          exit(130);
        },
      );
      if (sigintSub != null) {
        subscriptions.add(sigintSub);
      }

      final sigtermSub = listenForSignal(
        ProcessSignal.sigterm,
        (_) async {
          await _environmentService.cleanup(state);
          exit(130);
        },
      );
      if (sigtermSub != null) {
        subscriptions.add(sigtermSub);
      }

      final pipelineContext = SmartBuildContext(
        state: state,
        options: options,
      );
      final pipeline = StageRunner<SmartBuildContext>(
        stages: <Stage<SmartBuildContext>>[
          ValidateEnvStage<SmartBuildContext>(_environmentService),
          DiscoverModulesStage<SmartBuildContext>(_moduleGraphPort),
          AnalyzeDependenciesStage<SmartBuildContext>(_moduleGraphPort),
          const RetainTargetModuleStage(),
          BuildPlanStage<SmartBuildContext>(_moduleGraphPort),
        ],
      );

      final context = await pipeline.run(pipelineContext);

      if (context.state.modulePaths.isEmpty) {
        throw const CommandError(
          'No modules with build_runner found!',
          exitCode: 66,
        );
      }

      _printDependencySummary(context.dependencyReport);

      if (state.targetModule != null) {
        Logger.info(
          'Building ${state.targetModule} with ${state.modulePaths.length} total modules (including dependencies)',
        );
      }

      if (state.verbose || state.dryRun) {
        _printPlan(context.buildPlan);
      }

      if (!state.dryRun) {
        await _buildExecutionService.execute(state);
      }

      if (!state.dryRun && state.targetModule == null) {
        final graphContext = await GenerateGraphStage<SmartBuildContext>(
          _moduleGraphPort,
        ).run(context);
        _printGraphSummary(graphContext.graphReport);
      }

      log('');
      Logger.success('🏁 Smart build process completed!');
      log('');

      if (!state.dryRun && File('overview.md').existsSync()) {
        Logger.info('📊 View dependency graph: overview.md');
      }
      if (!state.dryRun && Directory(state.buildLogsDir).existsSync()) {
        Logger.info('📁 Build logs available in: ${state.buildLogsDir}/');
      }

      return 0;
    } on CommandError catch (error) {
      if (error.message.isNotEmpty) {
        Logger.error(error.message);
      }
      return error.exitCode;
    } on Object catch (e, stackTrace) {
      Logger.error('Fatal error: $e');
      if (state.verbose) {
        log(stackTrace);
      }
      return 1;
    } finally {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    }
  }

  void _printPlan(BuildPlan? plan) {
    if (plan == null) {
      return;
    }
    Console.write('');
    Console.info('📋 Build Plan');
    for (final wave in plan.waves) {
      Console.info('  Wave ${wave.level}: ${wave.modules.join(', ')}');
    }
  }

  void _printGraphSummary(GraphReport? report) {
    if (report == null) {
      return;
    }
    Console.write('');
    Console.success('Graph files generated:');
    for (final file in report.outputs) {
      Console.success('  ${file.title} → ${file.path}');
    }
  }

  void _printDependencySummary(DependencyReport? report) {
    if (report == null || report.unusedDependencies.isEmpty) {
      return;
    }
    Console.write('');
    Console.warning('Unused dependencies detected:');
    for (final entry in report.unusedDependencies.entries) {
      Console.warning('  ${entry.key}: ${entry.value.join(', ')}');
    }
  }
}
