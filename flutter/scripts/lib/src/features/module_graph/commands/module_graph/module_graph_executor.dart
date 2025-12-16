import 'dart:async';
import 'dart:io';

import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/codegen/domain/models/build_plan.dart';
import 'package:scripts/src/features/codegen/domain/models/build_state.dart';
import 'package:scripts/src/features/module_graph/commands/module_graph/module_graph_context.dart';
import 'package:scripts/src/features/module_graph/domain/models/dependency_report.dart';
import 'package:scripts/src/features/module_graph/domain/models/graph_report.dart';
import 'package:scripts/src/features/module_graph/domain/models/module_graph_options.dart';
import 'package:scripts/src/shared/ports/module_graph_port.dart';
import 'package:scripts/src/shared/services/environment_service.dart';
import 'package:scripts/src/shared/stages/analyze_dependencies_stage.dart';
import 'package:scripts/src/shared/stages/build_plan_stage.dart';
import 'package:scripts/src/shared/stages/discover_modules_stage.dart';
import 'package:scripts/src/shared/stages/generate_graph_stage.dart';
import 'package:scripts/src/shared/stages/validate_env_stage.dart';
import 'package:scripts/src/shared/utils/signal_utils.dart';

class ModuleGraphExecutor {
  ModuleGraphExecutor({
    required ModuleGraphPort moduleGraphPort,
    required EnvironmentService environmentService,
  }) : _moduleGraphPort = moduleGraphPort,
       _environmentService = environmentService;

  final ModuleGraphPort _moduleGraphPort;
  final EnvironmentService _environmentService;

  Future<int> run(ModuleGraphOptions options) async {
    final store = BuildStateStore();
    final state = store.configure(
      verbose: options.verbose,
      maxParallelBuilds: options.maxParallelBuilds,
    );
    Logger.configure(LoggerConfig(verbose: options.verbose));

    final subscriptions = <StreamSubscription<ProcessSignal>>[];

    log('');
    Logger.info('📊 Flutter Module Graph Generator');
    Logger.info('═══════════════════════════════════════');
    log('');

    try {
      if (state.verbose) {
        Logger.debug('Configuration:');
        Logger.debug('   Verbose: ${state.verbose}');
        Logger.debug('   Max Parallel: ${state.maxParallelBuilds}');
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

      final context = await StageRunner<ModuleGraphContext>(
        stages: <Stage<ModuleGraphContext>>[
          ValidateEnvStage<ModuleGraphContext>(_environmentService),
          DiscoverModulesStage<ModuleGraphContext>(_moduleGraphPort),
          AnalyzeDependenciesStage<ModuleGraphContext>(_moduleGraphPort),
          BuildPlanStage<ModuleGraphContext>(_moduleGraphPort),
          GenerateGraphStage<ModuleGraphContext>(_moduleGraphPort),
        ],
      ).run(
        ModuleGraphContext(
          state: state,
          options: options,
        ),
      );

      if (context.state.modulePaths.isEmpty) {
        throw const CommandError(
          'No modules with build_runner found!',
          exitCode: 66,
        );
      }

      _printSummary(
        context.buildPlan,
        context.dependencyReport,
        context.graphReport,
      );

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

  void _printSummary(
    BuildPlan? plan,
    DependencyReport? dependencyReport,
    GraphReport? graphReport,
  ) {
    Console.write('');
    if (plan != null) {
      Console.info('Build Waves:');
      for (final wave in plan.waves) {
        Console.info('  Wave ${wave.level}: ${wave.modules.join(', ')}');
      }
    }

    if (dependencyReport != null &&
        dependencyReport.unusedDependencies.isNotEmpty) {
      Console.write('');
      Console.warning('Unused dependencies detected:');
      for (final entry in dependencyReport.unusedDependencies.entries) {
        Console.warning('  ${entry.key}: ${entry.value.join(', ')}');
      }
    }

    if (graphReport != null) {
      Console.write('');
      Console.success('Graph files generated:');
      for (final file in graphReport.outputs) {
        Console.success('  ${file.title} → ${file.path}');
      }
    }
  }
}
