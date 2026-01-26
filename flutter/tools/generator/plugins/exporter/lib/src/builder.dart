import 'package:build/build.dart';

import 'services/export_options.dart';
import 'services/export_scanner.dart';
import 'services/export_writer.dart';

class ExporterBuilder implements Builder {
  ExporterBuilder({
    required BuilderOptions options,
    ExportScanner? scanner,
    ExportWriter? writer,
  }) : exportOptions = ExportOptions(options.config),
       _scanner = scanner ?? const ExportScanner(),
       _writer = writer ?? ExportWriter();

  final ExportOptions exportOptions;
  final ExportScanner _scanner;
  final ExportWriter _writer;

  @override
  Map<String, List<String>> get buildExtensions {
    return {
      r'$lib$': exportOptions.outputs,
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final aggregatedExports = <String>[];

    for (final folder in exportOptions.folders) {
      final exports = await _scanner
          .scanFolder(buildStep, folder)
          .map((uri) => "export '$uri';")
          .toList();
      if (exports.isEmpty) {
        continue;
      }
      if (exportOptions.isDedicated(folder)) {
        await _writer.write(
          buildStep,
          exports,
          exportOptions.outputForFolder(folder),
        );
      } else {
        aggregatedExports.addAll(exports);
      }
    }

    await _writer.write(
      buildStep,
      aggregatedExports,
      exportOptions.publicFile,
    );
  }
}
