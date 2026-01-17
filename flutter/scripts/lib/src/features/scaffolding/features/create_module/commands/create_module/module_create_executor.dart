import 'dart:io';

import 'package:scripts/src/features/scaffolding/domain/adapters/module_config_service.dart';
import 'package:scripts/src/features/scaffolding/features/create_module/engine/pipelines/module_create/module_create_context.dart';
import 'package:scripts/src/features/scaffolding/features/create_module/engine/pipelines/module_create/module_create_pipeline.dart';

class ModuleCreateExecutor {
  ModuleCreateExecutor({
    required ModuleConfigService moduleConfigService,
    String? workspaceRoot,
  })  : _pipeline = ModuleCreatePipeline(
          moduleConfigService: moduleConfigService,
          workspaceRoot: workspaceRoot ?? Directory.current.path,
        ),
        _workspaceRoot = workspaceRoot ?? Directory.current.path;

  final ModuleCreatePipeline _pipeline;
  final String _workspaceRoot;

  Future<int> run({
    required String featurePath,
    required String moduleType,
  }) {
    return _pipeline
        .run(
          ModuleCreateContext(
            featurePath: featurePath,
            moduleType: moduleType,
            workspaceRoot: _workspaceRoot,
          ),
        )
        .then((value) => value.exitCode);
  }
}
