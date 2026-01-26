import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/scaffolding/features/create_module/engine/pipelines/module_create/module_create_context.dart';

class ResolveTemplateStage implements Stage<ModuleCreateContext> {
  ResolveTemplateStage(this.workspaceRoot);

  final String workspaceRoot;

  @override
  String get name => 'resolve-template';

  @override
  Future<ModuleCreateContext> run(ModuleCreateContext context) async {
    final featureFolders = _buildFeatureFolderSegments(context.featureSegments);
    final templateDir = _resolveTemplateDirectory(context.normalizedModuleType);
    final templateName = p.basename(templateDir.path);
    final customPathSpec = _extractPathSpec(templateName);
    final featureName = context.featureSegments.last;
    final moduleName = customPathSpec != null
        ? featureName
        : '${featureName}_${context.normalizedModuleType}';
    final pathReplacements = <String, String>{
      'module_name': moduleName,
      'module_type': context.normalizedModuleType,
      'feature_name': featureName,
      'feature_path': context.featureSegments.join('/'),
    };
    // Base path under feature/, drop the leaf feature folder if custom path is provided
    final baseFeatureFolders = (customPathSpec != null && featureFolders.isNotEmpty)
        ? featureFolders.sublist(0, featureFolders.length - 1)
        : featureFolders;
    final moduleDirSegments = <String>[workspaceRoot, ...baseFeatureFolders];

    if (customPathSpec != null) {
      moduleDirSegments.addAll(
        _resolveCustomPathSegments(customPathSpec, pathReplacements),
      );
    } else {
      moduleDirSegments.add(context.normalizedModuleType);
    }

    final moduleDirPath = p.joinAll(moduleDirSegments);
    final moduleDir = Directory(moduleDirPath);

    if (moduleDir.existsSync()) {
      throw CommandError(
        'Module already exists: ${p.relative(moduleDir.path, from: workspaceRoot)}',
        exitCode: 64,
      );
    }

    context
      ..moduleDir = moduleDir
      ..templateDir = templateDir
      ..moduleName = moduleName
      ..replacements = pathReplacements;
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
      p.join(workspaceRoot, 'templates', 'modules'),
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

  Directory _resolveTemplateDirectory(String moduleType) {
    final templatesRoot = Directory(
      p.join(workspaceRoot, 'templates', 'modules'),
    );
    if (!templatesRoot.existsSync()) {
      throw CommandError(
        'Template root not found at ${p.relative(templatesRoot.path, from: workspaceRoot)}',
        exitCode: 64,
      );
    }

    final exact = Directory(p.join(templatesRoot.path, moduleType));
    if (exact.existsSync()) {
      return exact;
    }

    final matches = templatesRoot
        .listSync()
        .whereType<Directory>()
        .where(
          (dir) => p.basename(dir.path).startsWith('$moduleType.'),
        )
        .toList()
      ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));

    if (matches.isEmpty) {
      final available = _availableTemplates();
      final message = available.isEmpty
          ? 'Template for "$moduleType" not found under ${p.relative(templatesRoot.path, from: workspaceRoot)}.'
          : 'Template for "$moduleType" not found. Available templates: ${available.join(', ')}';
      throw CommandError(message, exitCode: 64);
    }

    if (matches.length > 1) {
      final names = matches.map((dir) => p.basename(dir.path)).join(', ');
      throw CommandError(
        'Multiple templates match "$moduleType": $names. Please keep only one variant.',
        exitCode: 64,
      );
    }

    return matches.first;
  }

  String? _extractPathSpec(String templateName) {
    final separatorIndex = templateName.indexOf('.');
    if (separatorIndex == -1) {
      return null;
    }
    return templateName.substring(separatorIndex + 1);
  }

  List<String> _resolveCustomPathSegments(
    String spec,
    Map<String, String> replacements,
  ) {
    var rendered = spec;
    replacements.forEach((key, value) {
      rendered = rendered.replaceAll('{{$key}}', value);
    });

    final segments = rendered
        .split(RegExp(r'[\\/]+'))
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (segments.isEmpty) {
      throw CommandError(
        'Custom path spec "$spec" resolved to an empty path.',
        exitCode: 64,
      );
    }
    for (final segment in segments) {
      if (segment == '.' || segment == '..' || segment.contains('..')) {
        throw CommandError(
          'Invalid path segment "$segment" in template path spec "$spec".',
          exitCode: 64,
        );
      }
    }
    return segments;
  }
}
