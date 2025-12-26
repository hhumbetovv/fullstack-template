import 'dart:async';
import 'dart:io';

import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/config/scripts_config.dart';
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
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/smart_build/build_log_reader.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/smart_build/error_module_analyzer.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/smart_build/git_change_detector.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/stages/filter_modules_stage.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/stages/retain_target_module_stage.dart';
import 'package:scripts/src/features/build_engine/utils/signal_utils.dart';

class SmartBuildExecutor {
  SmartBuildExecutor({
    required ModuleGraphPort moduleGraphPort,
    required EnvironmentService environmentService,
    required BuildExecutionService buildExecutionService,
    required BuildLogMetadataReader buildLogReader,
    required GitChangeDetector gitChangeDetector,
    required ErrorModuleAnalyzer errorModuleAnalyzer,
  }) : _moduleGraphPort = moduleGraphPort,
       _environmentService = environmentService,
       _buildExecutionService = buildExecutionService,
       _buildLogReader = buildLogReader,
       _gitChangeDetector = gitChangeDetector,
       _errorModuleAnalyzer = errorModuleAnalyzer;

  final ModuleGraphPort _moduleGraphPort;
  final EnvironmentService _environmentService;
  final BuildExecutionService _buildExecutionService;
  final BuildLogMetadataReader _buildLogReader;
  final GitChangeDetector _gitChangeDetector;
  final ErrorModuleAnalyzer _errorModuleAnalyzer;

  Future<int> run(SmartBuildOptions options) async {
    final store = BuildStateStore();
    final stopwatch = Stopwatch()..start();
    Logger.configure(LoggerConfig(verbose: options.verbose));

    final subscriptions = <StreamSubscription<ProcessSignal>>[];
    BuildState? activeState;

    log('');
    Logger.info('🎯 Flutter Smart Build System v2.0 (Dart)');
    Logger.info('════════════════════════════════════════');
    log('');

    try {
      BuildState captureStateForSignals() => activeState ?? store.state;

      final sigintSub = listenForSignal(
        ProcessSignal.sigint,
        (_) async {
          await _environmentService.cleanup(captureStateForSignals());
          exit(130);
        },
      );
      if (sigintSub != null) {
        subscriptions.add(sigintSub);
      }

      final sigtermSub = listenForSignal(
        ProcessSignal.sigterm,
        (_) async {
          await _environmentService.cleanup(captureStateForSignals());
          exit(130);
        },
      );
      if (sigtermSub != null) {
        subscriptions.add(sigtermSub);
      }

      var pass = 0;
      SmartBuildContext? finalContext;
      BuildState? finalState;

      while (true) {
        pass += 1;
        final state = store.configure(
          verbose: options.verbose,
          dryRun: options.dryRun,
          maxParallelBuilds: options.maxParallelBuilds,
          targetModule: options.targetModule,
          optimized: options.optimized,
          autoParallel: options.autoParallel,
        );
        if (options.mode == SmartBuildMode.error) {
          state.maxParallelBuilds = 1;
          state.autoParallel = false;
        }
        activeState = state;

        if (state.verbose) {
          Logger.debug('Configuration:');
          Logger.debug('   Verbose: ${state.verbose}');
          Logger.debug('   Dry Run: ${state.dryRun}');
          final parallelLabel = state.autoParallel
              ? '${state.maxParallelBuilds} (auto)'
              : '${state.maxParallelBuilds}';
          Logger.debug('   Max Parallel: $parallelLabel');
          Logger.debug('   Target Module: ${state.targetModule ?? 'all'}');
          Logger.debug(
            '   Scheduler: ${state.optimized ? 'optimized' : 'classic'}',
          );
          Logger.debug('   Mode: ${options.mode.description}');
          Logger.debug('   Working Directory: ${Directory.current.path}');
          if (pass > 1) {
            Logger.debug('   Error pass: $pass');
          }
          log('');
        } else if (pass > 1) {
          Logger.info('♻️  Error mode pass $pass starting...');
        }

        final pipelineStages = <Stage<SmartBuildContext>>[
          ValidateEnvStage<SmartBuildContext>(_environmentService),
          DiscoverModulesStage<SmartBuildContext>(_moduleGraphPort),
          AnalyzeDependenciesStage<SmartBuildContext>(_moduleGraphPort),
          FilterModulesStage(
            logReader: _buildLogReader,
            gitChangeDetector: _gitChangeDetector,
            errorModuleAnalyzer: _errorModuleAnalyzer,
          ),
          const RetainTargetModuleStage(),
          BuildPlanStage<SmartBuildContext>(_moduleGraphPort),
        ];

        final pipelineContext = SmartBuildContext(
          state: state,
          options: options,
          quiet: !state.verbose,
        );
        final totalStages = pipelineStages.length;
        var stageIndex = 0;
        final pipeline = StageRunner<SmartBuildContext>(
          stages: pipelineStages,
          onStageStart: (stageName) {
            stageIndex += 1;
            Logger.info(
              '🔁 Stage $stageIndex/$totalStages → $stageName',
            );
          },
        );

        final context = await pipeline.run(pipelineContext);

        if (context.skipBuild) {
          if (context.skipReason != null) {
            Logger.info(context.skipReason!);
          }
          Logger.info('🏁 No modules required building. Exiting.');
          return 0;
        }

        if (context.state.modulePaths.isEmpty) {
          throw const CommandError(
            'No modules with build_runner found!',
            exitCode: 66,
          );
        }

        if (!context.quiet) {
          _printDependencySummary(context.dependencyReport);
        }

        if (state.targetModule != null) {
          Logger.info(
            'Building ${state.targetModule} with ${state.modulePaths.length} total modules (including dependencies)',
          );
        }

        if (state.verbose || state.dryRun) {
          _printPlan(context.buildPlan);
        }

        var analyzerVerifiedDuringBuild = false;

        if (!state.dryRun) {
          await _buildExecutionService.execute(
            state,
            optimized: options.optimized,
            onModuleComplete: options.mode == SmartBuildMode.error
                ? (moduleName) async {
                    final continueBuilding = await _handleModuleCompletion(
                      context,
                    );
                    if (!continueBuilding) {
                      analyzerVerifiedDuringBuild = true;
                    }
                    return continueBuilding;
                  }
                : null,
          );
        }

        if (options.mode == SmartBuildMode.error &&
            !state.dryRun &&
            !analyzerVerifiedDuringBuild) {
          final remaining = await _findRemainingErrors(context);
          if (remaining.isNotEmpty) {
            Logger.warning(
              'Analyzer still reports issues in: ${remaining.join(', ')}',
            );
            Logger.info('Re-running error mode to rebuild remaining modules.');
            continue;
          }
        }

        finalContext = context;
        finalState = state;
        break;
      }

      if (!finalState.dryRun && finalState.targetModule == null) {
        final graphContext = await GenerateGraphStage<SmartBuildContext>(
          _moduleGraphPort,
        ).run(finalContext);
        _printGraphSummary(graphContext.graphReport);
      }

      log('');
      Logger.success('🏁 Smart build process completed!');
      log('');

      const graphOverview = ModuleGraphConfig.overviewFile;
      if (!finalState.dryRun && File(graphOverview).existsSync()) {
        Logger.info('📊 View dependency graph: $graphOverview');
      }
      if (!finalState.dryRun &&
          Directory(finalState.buildLogsDir).existsSync()) {
        Logger.info('📁 Build logs available in: ${finalState.buildLogsDir}/');
      }

      return 0;
    } on CommandError catch (error) {
      if (error.message.isNotEmpty) {
        Logger.error(error.message);
      }
      return error.exitCode;
    } on Object catch (e, stackTrace) {
      Logger.error('Fatal error: $e');
      final verbose = activeState?.verbose ?? options.verbose;
      if (verbose) {
        log(stackTrace);
      }
      return 1;
    } finally {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      stopwatch.stop();
      Logger.info(
        '⏱ Total elapsed time: ${_formatDuration(stopwatch.elapsed)}',
      );
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

  Future<bool> _handleModuleCompletion(
    SmartBuildContext context,
  ) async {
    final remaining = await _findRemainingErrors(context);
    if (remaining.isEmpty) {
      Logger.success('Analyzer clean. Stopping error-mode builds.');
      return false;
    }
    Logger.info(
      'Remaining modules with analyzer issues: ${remaining.join(', ')}',
    );
    return true;
  }

  Future<Set<String>> _findRemainingErrors(
    SmartBuildContext context,
  ) async {
    final modulePaths =
        context.graphState?.modulePaths ?? context.state.modulePaths;
    if (modulePaths.isEmpty) {
      return const <String>{};
    }
    final logMetadata = await _buildLogReader.read(
      context.state.buildLogsDir,
    );
    return _errorModuleAnalyzer.findProblematicModules(
      modulePaths: modulePaths,
      logMetadata: logMetadata,
    );
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final milliseconds = duration.inMilliseconds % 1000;

    final buffer = StringBuffer();
    if (minutes > 0) {
      buffer.write('${minutes}m ');
    }
    buffer.write('${seconds}s');
    if (minutes == 0 && milliseconds > 0) {
      buffer.write(' ${milliseconds}ms');
    }
    return buffer.toString().trim();
  }
}
