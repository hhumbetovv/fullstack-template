import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;

import 'generator_context.dart';

const _dartFormatWidth = '// dart format width=80';

class GeneratedOutputService {
  GeneratedOutputService({
    DartFormatter? formatter,
  }) : _formatter =
           formatter ??
           DartFormatter(
             languageVersion: DartFormatter.latestLanguageVersion,
           );

  final DartFormatter _formatter;

  Future<void> write({
    required GeneratorContext context,
    required String annotationName,
    required String content,
  }) async {
    final scaffolded = _scaffoldOutput(
      annotationName: annotationName,
      inputFileName: context.inputFileName,
      content: content,
    );

    var output = scaffolded;
    if (_isDartOutput(context.primaryOutput)) {
      output = _formatOrFallback(context, output);
    }

    await context.buildStep.writeAsString(context.primaryOutput, output);
  }

  String _scaffoldOutput({
    required String annotationName,
    required String inputFileName,
    required String content,
  }) {
    return '''
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// $annotationName Generator
// **************************************************************************

part of '$inputFileName';


$content
''';
  }

  String _formatOrFallback(GeneratorContext context, String code) {
    try {
      return _formatter.format('$_dartFormatWidth\n$code');
    } on Object catch (error, stack) {
      log.severe(
        '''
An error `${error.runtimeType}` occurred while formatting the generated source for
  `${context.inputPath}`
which was output to
  `${context.primaryOutput.path}`.
This may indicate an issue in the generator, the input source code, or in the
source formatter.''',
        error,
        stack,
      );
      return code;
    }
  }

  bool _isDartOutput(AssetId asset) => p.extension(asset.path) == '.dart';
}
