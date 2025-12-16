import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/scaffolding/engine/pipelines/module_create/module_create_context.dart';

class CopyTemplateStage implements Stage<ModuleCreateContext> {
  CopyTemplateStage(this.workspaceRoot);

  final String workspaceRoot;
  static const _emptyDirectoryMarkerName = '.template_dir';

  @override
  String get name => 'copy-template';

  @override
  Future<ModuleCreateContext> run(ModuleCreateContext context) async {
    final destination = context.moduleDir..createSync(recursive: true);

    _copyTemplateDirectory(
      source: context.templateDir,
      destination: destination,
      replacements: context.replacements,
    );
    _writeAnalysisOptions(destination);
    return context;
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
    final relativeInclude = p
        .relative(rootAnalysis.path, from: moduleDir.path)
        .replaceAll(r'\\', '/');
    File(
      p.join(moduleDir.path, 'analysis_options.yaml'),
    ).writeAsStringSync('include: $relativeInclude\n');
  }
}
