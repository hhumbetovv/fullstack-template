import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'console.dart';

Future<int> runBuildRunnerCommand(
  Directory directory,
  List<String> args,
) async {
  final commandArgs = ['run', 'build_runner', ...args];
  try {
    final process = await Process.start(
      'fvm',
      ['dart', ...commandArgs],
      workingDirectory: directory.path,
      mode: ProcessStartMode.inheritStdio,
    );
    return process.exitCode;
  } on ProcessException {
    final process = await Process.start(
      'dart',
      commandArgs,
      workingDirectory: directory.path,
      mode: ProcessStartMode.inheritStdio,
    );
    return process.exitCode;
  }
}

Future<Process> startBuildRunnerWatch(
  Directory directory,
  List<String> extraArgs,
) async {
  final args = ['dart', 'run', 'build_runner', 'watch', ...extraArgs];
  try {
    return await Process.start(
      'fvm',
      args,
      workingDirectory: directory.path,
      mode: ProcessStartMode.inheritStdio,
    );
  } on ProcessException {
    final process = await Process.start(
      'dart',
      ['run', 'build_runner', 'watch', ...extraArgs],
      workingDirectory: directory.path,
    );
    process.stdout
        .transform(const Utf8Decoder())
        .listen((event) => stdout.write(event));
    process.stderr
        .transform(const Utf8Decoder())
        .listen((event) => stdout.write(event));
    return process;
  }
}

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
    } on Exception catch (error) {
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
          } on Exception catch (error) {
            Console.warning('Failed to delete ${entity.path}: $error');
          }
        }
      }
    }
  } on Exception catch (error) {
    Console.warning('Failed to scan ${directory.path}: $error');
  }
}
