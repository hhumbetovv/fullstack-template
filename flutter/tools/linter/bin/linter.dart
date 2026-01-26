import 'dart:io';

import 'package:args/args.dart';
import 'package:feature_layer_linter/src/lint_engine.dart';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'root',
      abbr: 'r',
      help: 'Workspace root to scan (defaults to current directory).',
    )
    ..addFlag(
      'fix',
      defaultsTo: false,
      help: 'Reserved for future use (no automatic fixes yet).',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      defaultsTo: false,
      help: 'Enable verbose logging.',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show usage information.',
    );

  final results = parser.parse(args);
  if (results['help'] == true) {
    stdout
      ..writeln('Feature module linter')
      ..writeln(parser.usage);
    return;
  }

  final rootArg = results['root'] as String?;
  final root = Directory(rootArg ?? Directory.current.path);

  final engine = LintEngine(
    root: root,
    verbose: results['verbose'] as bool,
  );

  final violations = await engine.run();

  if (violations.isEmpty) {
    stdout.writeln('\x1B[32m✓ No errors found\x1B[0m');
    exit(0);
  }

  for (final v in violations) {
    stderr.writeln(v.render());
  }
  stderr.writeln('\n\x1B[31m✗ ${violations.length} ERROR(S) FOUND\x1B[0m');
  exit(1);
}
