import 'dart:async';
import 'dart:io';

import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/core/state/build_state.dart';
import 'package:scripts/src/feature/module_graph/services/build_planning.dart';
import 'package:scripts/src/feature/module_graph/services/dependency_analysis.dart';
import 'package:scripts/src/feature/module_graph/services/graph_generation.dart';
import 'package:scripts/src/feature/smart_build/command/options.dart';
import 'package:scripts/src/services/build_execution_service.dart';
import 'package:scripts/src/services/environment_service.dart';
import 'package:scripts/src/services/workspace_discovery_service.dart';

Future<int> runSmartBuild(SmartBuildOptions options) async {
  final store = BuildStateStore();
  final state = store.configure(
    verbose: options.verbose,
    dryRun: options.dryRun,
    maxParallelBuilds: options.maxParallelBuilds,
    targetModule: options.targetModule,
  );
  Logger.configure(LoggerConfig(verbose: options.verbose));
  const environmentService = EnvironmentService();
  final buildExecutionService = BuildExecutionService(state);

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

    await environmentService.validate();

    subscriptions
      ..add(
        ProcessSignal.sigint.watch().listen(
          (_) => environmentService.cleanup(state),
        ),
      )
      ..add(
        ProcessSignal.sigterm.watch().listen(
          (_) => environmentService.cleanup(state),
        ),
      );

    if (state.targetModule != null) {
      Logger.info('🎯 Building specific module: ${state.targetModule}');

      await discoverModulesFromRoot(state);

      if (state.modulePaths.containsKey(state.targetModule)) {
        await buildDependencyGraph(state);
        await analyzeUnusedModuleDependencies(state);

        final requiredModules = <String>{state.targetModule!};
        var changed = true;
        while (changed) {
          changed = false;
          for (final moduleName in requiredModules.toList()) {
            final dependencies =
                state.moduleDependencies[moduleName] ?? <String>{};
            for (final dep in dependencies) {
              if (!requiredModules.contains(dep)) {
                requiredModules.add(dep);
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

        Logger.info(
          'Building ${state.targetModule} with ${requiredModules.length} total modules (including dependencies)',
        );

        calculateBuildLevels(state);
        topologicalSort(state);

        if (state.verbose || state.dryRun) {
          showBuildPlan(state);
        }

        if (!state.dryRun) {
          await buildExecutionService.execute();
        }
      } else {
        throw SmartBuildException(
          'Module ${state.targetModule} not found among workspace packages.',
        );
      }
    } else {
      await discoverModulesFromRoot(state);

      if (state.modulePaths.isEmpty) {
        throw const SmartBuildException('No modules with build_runner found!');
      }

      await buildDependencyGraph(state);
      await analyzeUnusedModuleDependencies(state);
      calculateBuildLevels(state);
      await generateMermaidGraph(state);
      topologicalSort(state);

      if (state.verbose || state.dryRun) {
        showBuildPlan(state);
      }

      if (!state.dryRun) {
        await buildExecutionService.execute();
      }
    }

    log('');
    Logger.success('🏁 Smart build process completed!');
    log('');

    if (!state.dryRun && File('build_graph.md').existsSync()) {
      Logger.info('📊 View dependency graph: build_graph.md');
    }
    if (!state.dryRun && Directory(state.buildLogsDir).existsSync()) {
      Logger.info('📁 Build logs available in: ${state.buildLogsDir}/');
    }

    return 0;
  } on SmartBuildException catch (error) {
    if (error.message.isNotEmpty) {
      Logger.error(error.message);
    }
    return error.exitCode;
  } on Exception catch (e, stackTrace) {
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
