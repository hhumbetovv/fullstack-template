import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/scaffolding/features/create_module/engine/pipelines/module_create/module_create_context.dart';

class RegisterWorkspaceStage implements Stage<ModuleCreateContext> {
  RegisterWorkspaceStage(this.workspaceRoot);

  final String workspaceRoot;

  @override
  String get name => 'register-workspace';

  @override
  Future<ModuleCreateContext> run(ModuleCreateContext context) async {
    final workspaceModules = File(
      p.join(workspaceRoot, 'workspace_modules.yaml'),
    );

    if (!workspaceModules.existsSync()) {
      workspaceModules
        ..createSync(recursive: true)
        ..writeAsStringSync('modules:\n');
    }

    final relativePath =
        p.relative(context.moduleDir.path, from: context.workspaceRoot);
    final lines = workspaceModules.readAsLinesSync();
    final moduleEntry = '  - $relativePath';
    if (!lines.contains(moduleEntry)) {
      lines.add(moduleEntry);
      workspaceModules.writeAsStringSync('${lines.join('\n')}\n');
    }
    return context;
  }
}
