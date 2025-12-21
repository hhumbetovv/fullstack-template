import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/scaffolding/features/create_module/engine/pipelines/module_create/module_create_context.dart';

class RegisterWorkspaceStage implements Stage<ModuleCreateContext> {
  RegisterWorkspaceStage(this.workspaceRoot);

  final String workspaceRoot;

  @override
  String get name => 'register-workspace';

  @override
  Future<ModuleCreateContext> run(ModuleCreateContext context) async {
    final pubspecFile = File(p.join(workspaceRoot, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      throw CommandError(
        'Root pubspec.yaml not found at ${pubspecFile.path}',
        exitCode: 66,
      );
    }

    final relativePath = p.relative(
      context.moduleDir.path,
      from: context.workspaceRoot,
    );
    final normalizedPath = relativePath.replaceAll(r'\', '/');
    final moduleEntry = '- $normalizedPath';

    final originalContent = pubspecFile.readAsStringSync();
    final lineEnding = originalContent.contains('\r\n') ? '\r\n' : '\n';
    var lines = originalContent.split(RegExp(r'\r?\n'));
    var hadTrailingEmptyLine = false;
    if (lines.isNotEmpty && lines.last.isEmpty) {
      hadTrailingEmptyLine = true;
      lines = lines.sublist(0, lines.length - 1);
    }

    final alreadyRegistered = lines.any((line) {
      final trimmed = line.trim();
      return trimmed == moduleEntry || trimmed.startsWith('$moduleEntry ');
    });
    if (alreadyRegistered) {
      return context;
    }

    final workspaceIndex = lines.indexWhere(
      (line) => line.trimLeft().startsWith('workspace:'),
    );
    if (workspaceIndex == -1) {
      throw const CommandError(
        'Root pubspec.yaml is missing the workspace section.',
        exitCode: 66,
      );
    }

    var insertIndex = workspaceIndex + 1;
    while (insertIndex < lines.length) {
      final current = lines[insertIndex];
      final trimmedLeft = current.trimLeft();
      final indent = current.length - trimmedLeft.length;
      final isTopLevelKey = trimmedLeft.isNotEmpty && indent == 0 && !trimmedLeft.startsWith('#');
      if (isTopLevelKey) {
        break;
      }
      insertIndex++;
    }

    while (insertIndex > workspaceIndex + 1 && lines[insertIndex - 1].trim().isEmpty) {
      insertIndex--;
    }

    lines.insert(insertIndex, '  - $normalizedPath');

    final buffer = StringBuffer()..writeAll(lines, lineEnding);
    if (hadTrailingEmptyLine || originalContent.endsWith(lineEnding)) {
      buffer.write(lineEnding);
    }
    pubspecFile.writeAsStringSync(buffer.toString());
    return context;
  }
}
