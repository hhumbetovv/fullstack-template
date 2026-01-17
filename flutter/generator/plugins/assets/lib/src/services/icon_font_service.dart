import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:common_tooling/tooling.dart';
import 'package:path/path.dart' as p;

class IconFontService {
  Future<String> generate({
    required String packageRootPath,
    required String packageName,
    required String iconsDirAbsolute,
    required String fontOutputPath,
    required String className,
    required String classFileName,
    required bool normalize,
  }) async {
    final tempDir = await Directory.systemTemp.createTemp(
      'gen_assets_icon_font_',
    );
    try {
      final tempClassOutput = p.join(tempDir.path, classFileName);
      await Directory(p.dirname(tempClassOutput)).create(recursive: true);

      await _runIconFontGenerator(
        packageRootPath: packageRootPath,
        iconsDirAbsolute: iconsDirAbsolute,
        fontOutputPath: fontOutputPath,
        classOutputPath: tempClassOutput,
        className: className,
        packageName: packageName,
        normalize: normalize,
      );

      final rawClassContent = await File(tempClassOutput).readAsString();
      return _cleanIconFontContent(rawClassContent);
    } finally {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  Future<void> _runIconFontGenerator({
    required String packageRootPath,
    required String iconsDirAbsolute,
    required String fontOutputPath,
    required String classOutputPath,
    required String className,
    required String packageName,
    required bool normalize,
  }) async {
    final result = await runDartCommand(
      [
        'pub',
        'global',
        'run',
        'icon_font_generator:generator',
        iconsDirAbsolute,
        fontOutputPath,
        '--output-class-file=$classOutputPath',
        '--class-name=$className',
        '--package=$packageName',
        if (normalize) '--normalize' else '--no-normalize',
        '--recursive',
      ],
      workingDirectory: packageRootPath,
    );

    if (result.exitCode != 0) {
      final stdoutMessage = (result.stdout as Object?)?.toString().trim();
      final stderrMessage = (result.stderr as Object?)?.toString().trim();
      final buffer = StringBuffer(
        'icon_font_generator failed (exit code ${result.exitCode}).',
      );
      if (stdoutMessage?.isNotEmpty ?? false) {
        buffer
          ..write(' stdout: ')
          ..write(stdoutMessage);
      }
      if (stderrMessage?.isNotEmpty ?? false) {
        buffer
          ..write(' stderr: ')
          ..write(stderrMessage);
      }
      throw StateError(buffer.toString());
    }
  }

  String _cleanIconFontContent(String content) {
    final lines = LineSplitter.split(content).toList();
    final cleaned = <String>[];
    var sawHeader = false;
    var skippingBlockComment = false;

    for (final line in lines) {
      final trimmedLeft = line.trimLeft();

      if (skippingBlockComment) {
        if (trimmedLeft.contains('*/')) {
          skippingBlockComment = false;
        }
        continue;
      }

      final isSlashSlash = trimmedLeft.startsWith('//');
      final isDocComment = trimmedLeft.startsWith('///');

      if (!sawHeader &&
          isSlashSlash &&
          trimmedLeft.toLowerCase().startsWith('// generated code')) {
        cleaned.add(line);
        sawHeader = true;
        continue;
      }

      if (trimmedLeft.startsWith('/*')) {
        skippingBlockComment = !trimmedLeft.contains('*/');
        continue;
      }

      if (isSlashSlash || isDocComment) {
        continue;
      }

      cleaned.add(line);
    }

    return cleaned.join('\n');
  }
}
