import 'dart:async';
import 'dart:io';

import 'package:common_tooling/tooling.dart';
import 'package:path/path.dart' as p;
import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/shared/ports/build_runner_port.dart';

class BuildRunnerService implements BuildRunnerPort {
  const BuildRunnerService();

  @override
  Future<ProcessResult> runCommand(
    Directory directory,
    List<String> args, {
    bool forwardOutput = true,
  }) async {
    final commandArgs = ['run', 'build_runner', ...args];
    if (forwardOutput) {
      final process = await startDartCommand(
        commandArgs,
        workingDirectory: directory.path,
        mode: ProcessStartMode.inheritStdio,
      );
      final exitCode = await process.exitCode;
      return ProcessResult(process.pid, exitCode, '', '');
    }

    return runDartCommand(
      commandArgs,
      workingDirectory: directory.path,
    );
  }

  @override
  Future<Process> startWatch(
    Directory directory,
    List<String> extraArgs,
  ) async {
    final args = ['run', 'build_runner', 'watch', ...extraArgs];
    return startDartCommand(
      args,
      workingDirectory: directory.path,
      mode: ProcessStartMode.inheritStdio,
    );
  }

  @override
  Future<void> cancelProcesses(List<Process> processes) async {
    for (final process in processes) {
      final killed = process.kill(ProcessSignal.sigint);
      if (!killed) {
        process
          ..kill(ProcessSignal.sigterm)
          ..kill();
      }
    }
  }

  @override
  void deleteGeneratedArtifacts() {
    final patterns = <String>[
      '.g.dart',
      '.freezed.dart',
      '.gr.dart',
      '.module.dart',
      '.config.dart',
      'public.dart',
    ];

    final root = Directory.current;
    _deleteMatchingFiles(root, patterns);

    final buildDir = Directory(p.join(root.path, '.dart_tool', 'build'));
    if (buildDir.existsSync()) {
      try {
        buildDir.deleteSync(recursive: true);
      } on Object catch (error) {
        Console.warning('Failed to remove ${buildDir.path}: $error');
        return;
      }
      Console.info('Removed ${buildDir.path}');
    }
  }

  void _deleteMatchingFiles(Directory directory, List<String> patterns) {
    try {
      for (final entity in directory.listSync(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          final name = p.basename(entity.path);
          if (patterns.any(name.endsWith)) {
            try {
              entity.deleteSync();
            } on Object catch (error) {
              Console.warning('Failed to delete ${entity.path}: $error');
            }
          }
        }
      }
    } on Object catch (error) {
      Console.warning('Failed to scan ${directory.path}: $error');
    }
  }
}
