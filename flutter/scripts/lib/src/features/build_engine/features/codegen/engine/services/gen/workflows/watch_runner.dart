import 'dart:async';
import 'dart:io';

import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/features/build_engine/domain/models/module_descriptor.dart';
import 'package:scripts/src/features/build_engine/features/codegen/domain/ports/build_runner_port.dart';
import 'package:scripts/src/features/build_engine/utils/signal_utils.dart';

class WatchRunnerWorkflow {
  WatchRunnerWorkflow(this._buildRunner);

  final BuildRunnerPort _buildRunner;

  Future<int> execute(List<ModuleDescriptor> modules) async {
    if (modules.isEmpty) {
      Console.warning('No matching modules to watch.');
      return 0;
    }

    Console.write('🚀 Starting watch mode...');

    final processes = <Process>[];
    final completers = <Completer<void>>[];

    for (final module in modules) {
      Console.write('👀 ${module.path} (${module.name})');
      final process = await _buildRunner.startWatch(
        module.directory,
        ['-d', '--build-filter=package:${module.name}/**'],
      );
      processes.add(process);
      final completer = Completer<void>();
      completers.add(completer);
      unawaited(
        process.exitCode.then((code) {
          if (code != 0) {
            Console.error('Watcher for ${module.name} exited with code $code');
          }
          completer.complete();
        }),
      );
    }

    void cleanup() {
      unawaited(_buildRunner.cancelProcesses(processes));
    }

    final subscriptions = <StreamSubscription<ProcessSignal>>[];

    void registerSignal(ProcessSignal signal) {
      final sub = listenForSignal(signal, (_) {
        Console.warning('Stopping watchers...');
        cleanup();
      });
      if (sub != null) {
        subscriptions.add(sub);
      }
    }

    registerSignal(ProcessSignal.sigint);
    registerSignal(ProcessSignal.sigterm);

    await Future.wait(completers.map((c) => c.future));

    for (final subscription in subscriptions) {
      await subscription.cancel();
    }

    Console.success('Watchers stopped.');
    return 0;
  }
}
