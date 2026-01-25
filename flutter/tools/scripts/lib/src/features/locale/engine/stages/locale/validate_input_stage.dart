import 'dart:io';

import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/locale/engine/pipelines/locale/locale_context.dart';

class ValidateInputStage implements Stage<LocaleContext> {
  @override
  String get name => 'validate-input';

  @override
  Future<LocaleContext> run(LocaleContext context) async {
    final inputDir = Directory(context.inputPath);
    if (!inputDir.existsSync()) {
      throw CommandError(
        'Input directory not found: ${context.inputPath}',
        exitCode: 1,
      );
    }
    context.inputDir = inputDir;
    return context;
  }
}
