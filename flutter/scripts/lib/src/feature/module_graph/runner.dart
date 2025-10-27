import 'dart:async';
import 'dart:io';

import '../../core/core.dart';
import '../../services/environment_service.dart';
import '../../services/workspace_discovery_service.dart';

import 'dependency_graph.dart';
import 'options.dart';

Future<int> generateModuleGraph(ModuleGraphOptions options) async {
  configureState(
    verbose: options.verbose,
    maxParallelBuilds: options.maxParallelBuilds,
  );

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

    await validateEnvironment();

    subscriptions
      ..add(ProcessSignal.sigint.watch().listen((_) => cleanup()))
      ..add(ProcessSignal.sigterm.watch().listen((_) => cleanup()));

    await discoverModulesFromRoot();

    if (state.allModulePaths.isEmpty) {
      throw SmartBuildException(
        'No workspace modules discovered for graph generation.',
      );
    }

    await buildDependencyGraph();
    await analyzeUnusedModuleDependencies();
    calculateBuildLevels();
    await generateMermaidGraph();

    log('');
    Logger.success('✅ Dependency graph generated → build_graph.md');
    log('');

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
