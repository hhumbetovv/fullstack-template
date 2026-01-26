import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';

class ExportScanner {
  const ExportScanner();

  Stream<String> scanFolder(
    BuildStep buildStep,
    String folder,
  ) async* {
    final normalized = folder.trim();
    if (normalized.isEmpty) {
      return;
    }
    final glob = Glob('lib/src/$normalized/**');
    final assets = buildStep
        .findAssets(glob)
        .where((asset) => asset.path.endsWith('.dart'));

    await for (final asset in assets) {
      final exportUri = await _validateAsset(buildStep, asset);
      if (exportUri != null) {
        yield exportUri;
      }
    }
  }

  Future<String?> _validateAsset(BuildStep buildStep, AssetId asset) async {
    try {
      final content = await buildStep.readAsString(asset);
      final unit = parseString(content: content).unit;
      final hasPartDirective = unit.directives
          .whereType<PartOfDirective>()
          .isNotEmpty;
      final exportUri = asset.path.replaceFirst('lib/', '');
      if (!hasPartDirective && !exportUri.endsWith('.part')) {
        return exportUri;
      }
    } on Object {
      return null;
    }
    return null;
  }
}
