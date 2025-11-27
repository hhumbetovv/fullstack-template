import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scripts/src/core/logging/console.dart';

class ModuleCreateExecutor {
  ModuleCreateExecutor({String? workspaceRoot}) : workspaceRoot = workspaceRoot ?? Directory.current.path;
  static const _emptyDirectoryMarkerName = '.template_dir';

  final String workspaceRoot;

  Future<int> run({
    required String featurePath,
    required String moduleType,
  }) async {
    final featureSegments = _normalizeSegments(featurePath);
    if (featureSegments.isEmpty) {
      Console.error('Provide a feature path (e.g. profile or profile/edit).');
      return 64;
    }

    final normalizedModuleType = _normalizeSegment(moduleType);
    if (normalizedModuleType.isEmpty) {
      Console.error(
        'Provide the module type to create (e.g. data_api, domain).',
      );
      return 64;
    }

    final featureFolders = _buildFeatureFolderSegments(featureSegments);
    final moduleDirPath = p.joinAll([
      workspaceRoot,
      ...featureFolders,
      normalizedModuleType,
    ]);
    final moduleDir = Directory(moduleDirPath);

    if (moduleDir.existsSync()) {
      Console.error(
        'Module already exists: ${p.relative(moduleDir.path, from: workspaceRoot)}',
      );
      return 64;
    }

    final templateDir = Directory(
      p.join(
        workspaceRoot,
        'scripts',
        'templates',
        'modules',
        normalizedModuleType,
      ),
    );

    if (!templateDir.existsSync()) {
      final available = _availableTemplates();
      Console.error(
        'Template for "$normalizedModuleType" not found under ${p.relative(templateDir.path, from: workspaceRoot)}.',
      );
      if (available.isNotEmpty) {
        Console.write('Available templates: ${available.join(', ')}');
      }
      return 64;
    }

    moduleDir.createSync(recursive: true);

    final featureName = featureSegments.last;
    final moduleName = '${featureName}_$normalizedModuleType';
    final replacements = <String, String>{
      'module_name': moduleName,
      'feature_name': featureName,
      'module_type': normalizedModuleType,
      'feature_path': featureSegments.join('/'),
    };

    _copyTemplateDirectory(
      source: templateDir,
      destination: moduleDir,
      replacements: replacements,
    );
    _writeAnalysisOptions(moduleDir);
    _registerModuleInWorkspace(moduleDir);

    Console.success(
      'Module scaffolded at ${p.relative(moduleDir.path, from: workspaceRoot)}',
    );
    return 0;
  }

  List<String> _normalizeSegments(String input) {
    final sanitized = input
        .split(RegExp(r'[\\/]+'))
        .map(_normalizeSegment)
        .where((segment) => segment.isNotEmpty)
        .toList();
    return sanitized;
  }

  String _normalizeSegment(String input) {
    final trimmed = input.trim().toLowerCase();
    final replaced = trimmed.replaceAll(RegExp('[^a-z0-9]+'), '_');
    final collapsed = replaced.replaceAll(RegExp('_+'), '_');
    return collapsed.replaceAll(RegExp(r'^_|_$'), '');
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

  void _copyTemplateDirectory({
    required Directory source,
    required Directory destination,
    required Map<String, String> replacements,
  }) {
    for (final entity in source.listSync(recursive: false)) {
      if (entity is Directory) {
        final targetDir = Directory(
          p.join(destination.path, p.basename(entity.path)),
        )..createSync(recursive: true);
        _copyTemplateDirectory(
          source: entity,
          destination: targetDir,
          replacements: replacements,
        );
        continue;
      }

      if (entity is File) {
        final fileName = p.basename(entity.path);
        if (fileName == _emptyDirectoryMarkerName) {
          // Marker file used to keep empty directories in version control.
          continue;
        }
        final targetFile = File(p.join(destination.path, fileName));
        targetFile.parent.createSync(recursive: true);
        _copyTemplateFile(entity, targetFile, replacements);
      }
    }
  }

  void _copyTemplateFile(
    File source,
    File target,
    Map<String, String> replacements,
  ) {
    final bytes = source.readAsBytesSync();
    try {
      final content = utf8.decode(bytes);
      target.writeAsStringSync(_applyReplacements(content, replacements));
      return;
    } on FormatException {
      // Fall through and copy bytes if the file is not UTF-8 text.
    }
    target.writeAsBytesSync(bytes);
  }

  String _applyReplacements(String content, Map<String, String> replacements) {
    var result = content;
    replacements.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value);
    });
    return result;
  }

  void _writeAnalysisOptions(Directory moduleDir) {
    final rootAnalysis = File(p.join(workspaceRoot, 'analysis_options.yaml'));
    if (!rootAnalysis.existsSync()) {
      Console.warning(
        'Root analysis_options.yaml not found. Skipping include.',
      );
      return;
    }
    final relativeInclude = p.relative(rootAnalysis.path, from: moduleDir.path).replaceAll(r'\', '/');
    File(p.join(moduleDir.path, 'analysis_options.yaml')).writeAsStringSync('include: $relativeInclude\n');
  }

  void _registerModuleInWorkspace(Directory moduleDir) {
    final pubspecFile = File(p.join(workspaceRoot, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      Console.warning('Root pubspec.yaml not found. Workspace not updated.');
      return;
    }

    final lines = pubspecFile.readAsLinesSync();
    final workspaceIndex = lines.indexWhere(
      (line) => line.trim() == 'workspace:',
    );
    if (workspaceIndex == -1) {
      Console.warning('workspace: section missing in pubspec.yaml.');
      return;
    }

    final modulePath = p.relative(moduleDir.path, from: workspaceRoot).replaceAll(r'\', '/');
    final entry = '  - $modulePath';

    final insertionIndex = _findWorkspaceInsertionIndex(lines, workspaceIndex);
    final existingLines = lines.sublist(workspaceIndex + 1, insertionIndex).map((line) => line.trim());
    if (existingLines.contains('- $modulePath')) {
      Console.info('Workspace already references $modulePath.');
      return;
    }

    lines.insert(insertionIndex, entry);
    pubspecFile.writeAsStringSync('${lines.join('\n')}\n');
    Console.success('Added $modulePath to workspace.');
  }

  int _findWorkspaceInsertionIndex(List<String> lines, int workspaceIndex) {
    for (var i = workspaceIndex + 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) {
        return i;
      }
      final leadingSpaces = line.length - line.trimLeft().length;
      if (leadingSpaces < 2) {
        return i;
      }
    }
    return lines.length;
  }

  List<String> _availableTemplates() {
    final modulesDir = Directory(
      p.join(workspaceRoot, 'scripts', 'templates', 'modules'),
    );
    if (!modulesDir.existsSync()) {
      return const [];
    }
    final templates = modulesDir.listSync().whereType<Directory>().map((dir) => p.basename(dir.path)).toList()..sort();
    return templates;
  }
}
