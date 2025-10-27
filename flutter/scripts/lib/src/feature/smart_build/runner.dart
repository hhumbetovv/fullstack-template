import 'dart:async';
import 'dart:io';

import '../../core/core.dart';
import '../../services/build_execution_service.dart';
import '../../services/environment_service.dart';
import '../../services/workspace_discovery_service.dart';

import '../module_graph/dependency_graph.dart';
import 'options.dart';

Future<int> runSmartBuild(SmartBuildOptions options) async {
  configureState(
    verbose: options.verbose,
    dryRun: options.dryRun,
    maxParallelBuilds: options.maxParallelBuilds,
    targetModule: options.targetModule,
  );

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

    await validateEnvironment();

    subscriptions
      ..add(ProcessSignal.sigint.watch().listen((_) => cleanup()))
      ..add(ProcessSignal.sigterm.watch().listen((_) => cleanup()));

    if (state.targetModule != null) {
      Logger.info('🎯 Building specific module: ${state.targetModule}');

      await discoverModulesFromRoot();

      if (state.modulePaths.containsKey(state.targetModule)) {
        await buildDependencyGraph();
        await analyzeUnusedModuleDependencies();

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

        calculateBuildLevels();
        topologicalSort();

        if (state.verbose || state.dryRun) {
          showBuildPlan();
        }

        if (!state.dryRun) {
          await executeSmartBuild();
        }
      } else {
        throw SmartBuildException(
          'Module ${state.targetModule} not found among workspace packages.',
        );
      }
    } else {
      await discoverModulesFromRoot();

      if (state.modulePaths.isEmpty) {
        throw SmartBuildException('No modules with build_runner found!');
      }

      await buildDependencyGraph();
      await analyzeUnusedModuleDependencies();
      calculateBuildLevels();
      await generateMermaidGraph();
      topologicalSort();

      if (state.verbose || state.dryRun) {
        showBuildPlan();
      }

      if (!state.dryRun) {
        await executeSmartBuild();
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
