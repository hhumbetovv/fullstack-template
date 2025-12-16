import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/features/links/adapters/link_creator.dart';

class LinksExecutor {
  LinksExecutor({required LinkCreator linkCreator})
    : _linkCreator = linkCreator;

  final LinkCreator _linkCreator;

  Future<int> runBuildLinks() async {
    _printHeader('Build Symlinks Creator');

    final summary = await _linkCreator.create(
      fileName: 'build.yaml',
      outputDir: 'yaml/builds',
    );

    _reportSummary(summary);
    return summary.failed > 0 ? 1 : 0;
  }

  Future<int> runPubspecLinks() async {
    _printHeader('Pubspec Symlinks Creator');

    final summary = await _linkCreator.create(
      fileName: 'pubspec.yaml',
      outputDir: 'yaml/pubspecs',
    );

    _reportSummary(summary);
    return summary.failed > 0 ? 1 : 0;
  }

  Future<int> runYamlLinks() async {
    Console.write('=== Pubspec Symlinks ===');
    final pubspecSummary = await _linkCreator.create(
      fileName: 'pubspec.yaml',
      outputDir: 'yaml/pubspecs',
    );

    Console.write('\n=== Build Symlinks ===');
    final buildSummary = await _linkCreator.create(
      fileName: 'build.yaml',
      outputDir: 'yaml/builds',
    );

    Console.write('\n=====================================');
    Console.success(
      '✓ Pubspec symlinks: ${pubspecSummary.created}, build symlinks: ${buildSummary.created}',
    );
    final failures = pubspecSummary.failed + buildSummary.failed;
    if (failures > 0) {
      Console.error('✗ Failures encountered: $failures');
    }
    Console.write('=====================================');

    return failures > 0 ? 1 : 0;
  }

  void _printHeader(String title) {
    Console.write('=====================================');
    Console.write('    $title');
    Console.write('=====================================');
  }

  void _reportSummary(LinkSummary summary) {
    Console.write('\n=====================================');
    Console.success('✓ Total symlinks created: ${summary.created}');
    if (summary.failed > 0) {
      Console.error('✗ Failed: ${summary.failed}');
    }
    Console.write('=====================================');

    if (summary.failed > 0) {
      Console.error('Some symlinks failed to create.');
    } else {
      Console.success('Script completed successfully!');
    }
  }
}
