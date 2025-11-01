import 'dart:async';
import 'dart:io';

import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/core/state/build_state.dart';
import 'package:scripts/src/feature/module_graph/command/options.dart';
import 'package:scripts/src/feature/module_graph/services/build_planning.dart';
import 'package:scripts/src/feature/module_graph/services/dependency_analysis.dart';
import 'package:scripts/src/feature/module_graph/services/graph_generation.dart';
import 'package:scripts/src/services/environment_service.dart';
import 'package:scripts/src/services/workspace_discovery_service.dart';

Future<int> generateModuleGraph(ModuleGraphOptions options) async {
  final store = BuildStateStore();
  final state = store.configure(
    verbose: options.verbose,
    maxParallelBuilds: options.maxParallelBuilds,
  );
  Logger.configure(LoggerConfig(verbose: options.verbose));
  const environmentService = EnvironmentService();

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

    await discoverModulesFromRoot(state);

    if (state.allModulePaths.isEmpty) {
      throw const SmartBuildException(
        'No workspace modules discovered for graph generation.',
      );
    }

    await buildDependencyGraph(state);
    await analyzeUnusedModuleDependencies(state);
    calculateBuildLevels(state);
    await generateMermaidGraph(state);

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
