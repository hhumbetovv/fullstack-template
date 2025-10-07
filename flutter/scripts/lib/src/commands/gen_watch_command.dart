import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:scripts/src/common/build_runner.dart';
import 'package:scripts/src/common/console.dart';
import 'package:scripts/src/common/options.dart';
import 'package:scripts/src/common/workspace.dart';
import 'package:scripts/src/feature/smart_build/runner.dart';

class GenWatchCommand extends Command<int> {
  GenWatchCommand() {
    argParser.addFlag(
      'pre-build',
      help: 'Run smart-build before starting watchers.',
      negatable: false,
    );
  }

  @override
  String get name => 'gen-watch';

  @override
  String get description =>
      'Run build_runner watch for modules, optionally limited to specific names.';

  @override
  Future<int> run() async {
    final modules = await discoverModules(includeNonBuildRunner: false);
    if (modules.isEmpty) {
      Console.warning('No modules with build_runner were found.');
      return 0;
    }

    final targets = <ModuleInfo>[];
    final rest = argResults?.rest ?? <String>[];
    if (rest.isEmpty) {
      targets.addAll(modules);
    } else {
      for (final value in rest) {
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

    final preBuild = argResults?['pre-build'] as bool? ?? false;
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
}
