import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/scaffolding/engine/pipelines/module_create/module_create_context.dart';

class ResolveTemplateStage implements Stage<ModuleCreateContext> {
  ResolveTemplateStage(this.workspaceRoot);

  final String workspaceRoot;

  @override
  String get name => 'resolve-template';

  @override
  Future<ModuleCreateContext> run(ModuleCreateContext context) async {
    final featureFolders = _buildFeatureFolderSegments(context.featureSegments);
    final moduleDirPath = p.joinAll([
      workspaceRoot,
      ...featureFolders,
      context.normalizedModuleType,
    ]);
    final moduleDir = Directory(moduleDirPath);

    if (moduleDir.existsSync()) {
      throw CommandError(
        'Module already exists: ${p.relative(moduleDir.path, from: workspaceRoot)}',
        exitCode: 64,
      );
    }

    final templateDir = Directory(
      p.join(
        workspaceRoot,
        'scripts',
        'templates',
        'modules',
        context.normalizedModuleType,
      ),
    );

    if (!templateDir.existsSync()) {
      final available = _availableTemplates();
      final relative = p.relative(templateDir.path, from: workspaceRoot);
      final message = available.isEmpty
          ? 'Template for "${context.normalizedModuleType}" not found under $relative.'
          : 'Template for "${context.normalizedModuleType}" not found under $relative. Available templates: ${available.join(', ')}';
      throw CommandError(message, exitCode: 64);
    }

    final featureName = context.featureSegments.last;
    final moduleName = '${featureName}_${context.normalizedModuleType}';

    context
      ..moduleDir = moduleDir
      ..templateDir = templateDir
      ..moduleName = moduleName
      ..replacements = <String, String>{
        'module_name': moduleName,
        'feature_name': featureName,
        'module_type': context.normalizedModuleType,
        'feature_path': context.featureSegments.join('/'),
      };
    return context;
  }

  List<String> _buildFeatureFolderSegments(List<String> featureSegments) {
    final folders = <String>['feature', featureSegments.first];
    for (final segment in featureSegments.skip(1)) {
      folders
        ..add('feature')
        ..add(segment);
    }
    return folders;
  }

  List<String> _availableTemplates() {
    final templatesDir = Directory(
      p.join(workspaceRoot, 'scripts', 'templates', 'modules'),
    );
    if (!templatesDir.existsSync()) {
      return const [];
    }
    return templatesDir
        .listSync()
        .whereType<Directory>()
        .map((dir) => p.basename(dir.path))
        .toList()
      ..sort();
  }
}
