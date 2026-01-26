import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';

class ExportWriter {
  ExportWriter({
    DartFormatter? formatter,
  }) : _formatter =
           formatter ??
           DartFormatter(
             languageVersion: DartFormatter.latestLanguageVersion,
           );

  final DartFormatter _formatter;

  Future<void> write(
    BuildStep buildStep,
    List<String> exports,
    String outputRelativePath,
  ) async {
    if (exports.isEmpty) return;

    exports
      ..sort()
      ..add('');

    final content = _formatter.format(exports.join('\n'));
    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, 'lib/$outputRelativePath'),
      content,
    );
  }
}
