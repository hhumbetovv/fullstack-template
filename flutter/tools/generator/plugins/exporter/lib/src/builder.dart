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
      r'$lib$': ['public.dart'],
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final exports = await _scanner
        .scanExports(buildStep, exportOptions.folders)
        .map((uri) => "export '$uri';")
        .toList();

    await _writer.write(buildStep, exports);
  }
}
