import 'dart:async';
import 'dart:io';

import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/feature/smart_build/command/options.dart';
import 'package:scripts/src/feature/smart_build/runner/runner.dart';
import 'package:scripts/src/services/build_runner_service.dart';
import 'package:scripts/src/services/workspace_service.dart';

Future<int> runGenWatchFeature({
  required bool preBuild,
  required Iterable<String> filters,
}) async {
  final modules = await discoverModules(includeNonBuildRunner: false);
  if (modules.isEmpty) {
    Console.warning('No modules with build_runner were found.');
    return 0;
  }

  final targets = <ModuleInfo>[];
  if (filters.isEmpty) {
    targets.addAll(modules);
  } else {
    for (final value in filters) {
      final module = findModule(modules, value);
      if (module == null) {
        Console.warning("Module '$value' not found, skipping...");
        continue;
      }
      targets.add(module);
    }
  }

  if (targets.isEmpty) {
    Console.warning('No matching modules to watch.');
    return 0;
  }

  if (preBuild) {
    Console.info('Running smart-build before starting watchers...');
    final exitCode = await runSmartBuild(
      const SmartBuildOptions(
        verbose: false,
        dryRun: false,
        maxParallelBuilds: 4,
      ),
    );
    if (exitCode != 0) {
      Console.error(
        'smart-build failed (exit code $exitCode). Continuing watchers.',
      );
    }
  }

  Console.write('🚀 Starting watch mode...');

  final processes = <Process>[];
  final completers = <Completer<void>>[];

  for (final module in targets) {
    Console.write('👀 ${module.path} (${module.name})');
    final process = await startBuildRunnerWatch(module.directory, ['-d']);
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
    cancelProcesses(processes);
  }

  final subscriptions = <StreamSubscription<ProcessSignal>>[
    ProcessSignal.sigint.watch().listen((_) {
      Console.warning('Stopping watchers...');
      cleanup();
    }),
    ProcessSignal.sigterm.watch().listen((_) {
      Console.warning('Stopping watchers...');
      cleanup();
    }),
  ];

  await Future.wait(completers.map((c) => c.future));

  for (final subscription in subscriptions) {
    await subscription.cancel();
  }

  Console.success('Watchers stopped.');
  return 0;
}
