import 'dart:async';
import 'dart:io';

import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/core/state/build_state.dart';
import 'package:scripts/src/domain/models/build_plan.dart';
import 'package:scripts/src/domain/models/dependency_report.dart';
import 'package:scripts/src/domain/models/graph_report.dart';
import 'package:scripts/src/domain/models/module_graph_options.dart';
import 'package:scripts/src/domain/ports/module_graph_port.dart';
import 'package:scripts/src/services/environment_service.dart';

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

      await _moduleGraphPort.discoverModules(state);

      final dependencyReport = await _moduleGraphPort.analyzeDependencies(
        state,
      );
      final plan = _moduleGraphPort.buildPlan(state);
      final graphReport = await _moduleGraphPort.generateGraphFiles(state);

      _printSummary(plan, dependencyReport, graphReport);

      return 0;
    } on CommandError catch (error) {
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

  void _printSummary(
    BuildPlan plan,
    DependencyReport dependencyReport,
    GraphReport graphReport,
  ) {
    Console.write('');
    Console.info('Build Waves:');
    for (final wave in plan.waves) {
      Console.info('  Wave ${wave.level}: ${wave.modules.join(', ')}');
    }

    if (dependencyReport.unusedDependencies.isNotEmpty) {
      Console.write('');
      Console.warning('Unused dependencies detected:');
      for (final entry in dependencyReport.unusedDependencies.entries) {
        Console.warning('  ${entry.key}: ${entry.value.join(', ')}');
      }
    }

    Console.write('');
    Console.success('Graph files generated:');
    for (final file in graphReport.outputs) {
      Console.success('  ${file.title} → ${file.path}');
    }
  }
}
