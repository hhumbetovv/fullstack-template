import 'dart:io';

import 'package:path/path.dart' as p;

class ToolchainException implements Exception {
  const ToolchainException(this.message);

  final String message;

  @override
  String toString() => 'ToolchainException: $message';
}

class _ResolvedCommand {
  _ResolvedCommand(this.executable, this.leadingArgs);

  final String executable;
  final List<String> leadingArgs;

  List<String> buildArgs(List<String> args) => <String>[
    ...leadingArgs,
    ...args,
  ];
}

Future<void> ensureDartOrFvm({
  String? workingDirectory,
  bool requirePubspec = false,
}) async {
  await _resolveDartCommand(workingDirectory);

  if (!requirePubspec) return;

  final candidate = File(
    p.join(workingDirectory ?? Directory.current.path, 'pubspec.yaml'),
  );
  if (!candidate.existsSync()) {
    throw const ToolchainException(
      'No pubspec.yaml found in the current working directory.',
    );
  }
}

Future<ProcessResult> runDartCommand(
  List<String> args, {
  String? workingDirectory,
  bool runInShell = false,
}) async {
  final resolution = await _resolveDartCommand(workingDirectory);
  return Process.run(
    resolution.executable,
    resolution.buildArgs(args),
    workingDirectory: workingDirectory,
    runInShell: runInShell,
  );
}

Future<Process> startDartCommand(
  List<String> args, {
  String? workingDirectory,
  ProcessStartMode mode = ProcessStartMode.normal,
}) async {
  final resolution = await _resolveDartCommand(workingDirectory);
  return Process.start(
    resolution.executable,
    resolution.buildArgs(args),
    workingDirectory: workingDirectory,
    mode: mode,
  );
}

Future<_ResolvedCommand> _resolveDartCommand(String? workingDirectory) async {
  final root = workingDirectory ?? Directory.current.path;
  final hasLocalFvm = Directory(p.join(root, '.fvm')).existsSync();
  final hasFvm = await _hasCommand('fvm');
  final hasDart = await _hasCommand('dart');

  if (hasLocalFvm && hasFvm) {
    return _ResolvedCommand('fvm', const ['dart']);
  }

  if (hasDart) {
    return _ResolvedCommand('dart', const []);
  }

  if (hasFvm) {
    return _ResolvedCommand('fvm', const ['dart']);
  }

  throw const ToolchainException(
    "Neither 'dart' nor 'fvm' command found in PATH.",
  );
}

Future<bool> _hasCommand(String command) async {
  final probe = Platform.isWindows ? 'where' : 'which';
  try {
    final result = await Process.run(probe, [command]);
    return result.exitCode == 0;
  } on Object {
    return false;
  }
}
