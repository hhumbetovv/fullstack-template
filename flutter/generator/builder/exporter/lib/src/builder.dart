import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';

class ExporterBuilder implements Builder {
  ExporterBuilder({
    required this.options,
  });

  BuilderOptions options;

  @override
  Map<String, List<String>> get buildExtensions {
    return {
      r'$lib$': ['public.dart'],
    };
  }

  List<String> get folders => (options.config['folders'] as List?)?.cast<String>() ?? [];

  String get packageName => options.config['project_name'] as String? ?? 'exports';

  @override
  Future<void> build(BuildStep buildStep) async {
    final expList = <String>[];

    for (final folder in folders) {
      final exports = buildStep.findAssets(Glob('lib/src/$folder/**'));

      await for (final exportLibrary in exports) {
        try {
          final con = await buildStep.readAsString(exportLibrary);
          final ast = parseString(content: con).unit.childEntities;

          final exportUri = exportLibrary.path.replaceFirst('lib/', '');

          if (ast.whereType<PartOfDirective>().isEmpty && !exportUri.endsWith('.part')) {
            expList.add(
              "export '$exportUri';",
            );
          }
        } on Exception {
          continue;
        }
      }
    }

    if (expList.isNotEmpty) {
      expList
        ..sort()
        ..add('');

      await buildStep.writeAsString(
        AssetId(buildStep.inputId.package, 'lib/public.dart'),
        DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format(expList.join('\n')),
      );
    }
  }
}
