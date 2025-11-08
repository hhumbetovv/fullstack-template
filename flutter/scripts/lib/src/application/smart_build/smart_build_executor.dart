import 'dart:async';
import 'dart:io';

import 'package:scripts/src/application/workspace/workspace_state_loader.dart';
import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/core/state/build_state.dart';
import 'package:scripts/src/domain/models/build_plan.dart';
import 'package:scripts/src/domain/models/dependency_report.dart';
import 'package:scripts/src/domain/models/graph_report.dart';
import 'package:scripts/src/domain/models/smart_build_options.dart';
import 'package:scripts/src/domain/ports/module_graph_port.dart';
import 'package:scripts/src/services/build_execution_service.dart';
import 'package:scripts/src/services/environment_service.dart';

class SmartBuildExecutor {
  SmartBuildExecutor({
    required ModuleGraphPort moduleGraphPort,
    required EnvironmentService environmentService,
    required WorkspaceStateLoader workspaceStateLoader,
    required BuildExecutionService buildExecutionService,
  }) : _moduleGraphPort = moduleGraphPort,
       _environmentService = environmentService,
       _workspaceStateLoader = workspaceStateLoader,
       _buildExecutionService = buildExecutionService;

  final ModuleGraphPort _moduleGraphPort;
  final EnvironmentService _environmentService;
  final WorkspaceStateLoader _workspaceStateLoader;
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

      await _environmentService.validate();

      subscriptions
        ..add(
          ProcessSignal.sigint.watch().listen(
            (_) => _environmentService.cleanup(state),
          ),
        )
        ..add(
          ProcessSignal.sigterm.watch().listen(
            (_) => _environmentService.cleanup(state),
          ),
        );

      await _workspaceStateLoader.load(state);

      if (state.modulePaths.isEmpty) {
        throw const CommandError(
          'No modules with build_runner found!',
          exitCode: 66,
        );
      }

      final dependencyReport = await _moduleGraphPort.analyzeDependencies(
        state,
      );
      _printDependencySummary(dependencyReport);

      if (state.targetModule != null) {
        _retainTargetModule(state, state.targetModule!);
        Logger.info(
          'Building ${state.targetModule} with ${state.modulePaths.length} total modules (including dependencies)',
        );
      }

      final plan = _moduleGraphPort.buildPlan(state);

      if (state.verbose || state.dryRun) {
        _printPlan(plan);
      }

      if (!state.dryRun) {
        await _buildExecutionService.execute(state);
      }

      if (!state.dryRun && state.targetModule == null) {
        final graphReport = await _moduleGraphPort.generateGraphFiles(state);
        _printGraphSummary(graphReport);
      }

      log('');
      Logger.success('🏁 Smart build process completed!');
      log('');

      if (!state.dryRun && File('graph.md').existsSync()) {
        Logger.info('📊 View dependency graph: graph.md');
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

  void _retainTargetModule(BuildState state, String target) {
    if (!state.modulePaths.containsKey(target)) {
      throw CommandError(
        'Module $target not found among workspace packages.',
        exitCode: 64,
      );
    }

    final requiredModules = <String>{target};
    var changed = true;
    while (changed) {
      changed = false;
      for (final moduleName in requiredModules.toList()) {
        final dependencies = state.moduleDependencies[moduleName] ?? <String>{};
        for (final dep in dependencies) {
          if (requiredModules.add(dep)) {
            changed = true;
            Logger.debug('Added required dependency: $dep');
          }
        }
      }
    }

    final modulesToRemove = <String>[];
    for (final moduleName in state.modulePaths.keys) {
      if (!requiredModules.contains(moduleName)) {
        modulesToRemove.add(moduleName);
      }
    }

    for (final moduleName in modulesToRemove) {
      state.modulePaths.remove(moduleName);
      state.moduleDependencies.remove(moduleName);
      state.moduleBuildStatus.remove(moduleName);
      state.allModulePaths.remove(moduleName);
      state.allModuleDependencies.remove(moduleName);
      state.moduleUnusedDependencies.remove(moduleName);
    }

    for (final deps in state.moduleDependencies.values) {
      deps.removeWhere(modulesToRemove.contains);
    }
    for (final deps in state.allModuleDependencies.values) {
      deps.removeWhere(modulesToRemove.contains);
    }
    for (final deps in state.moduleUnusedDependencies.values) {
      deps.removeWhere(modulesToRemove.contains);
    }

    state.invalidateWorkspaceSnapshot();
  }

  void _printPlan(BuildPlan plan) {
    Console.write('');
    Console.info('📋 Build Plan');
    for (final wave in plan.waves) {
      Console.info('  Wave ${wave.level}: ${wave.modules.join(', ')}');
    }
  }

  void _printGraphSummary(GraphReport report) {
    Console.write('');
    Console.success('Graph files generated:');
    for (final file in report.outputs) {
      Console.success('  ${file.title} → ${file.path}');
    }
  }

  void _printDependencySummary(DependencyReport report) {
    if (report.unusedDependencies.isEmpty) {
      return;
    }
    Console.write('');
    Console.warning('Unused dependencies detected:');
    for (final entry in report.unusedDependencies.entries) {
      Console.warning('  ${entry.key}: ${entry.value.join(', ')}');
    }
  }
}
