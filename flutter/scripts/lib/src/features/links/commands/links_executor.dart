import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/features/links/domain/adapters/link_creator.dart';
import 'package:scripts/src/features/links/engine/pipelines/link_pipeline.dart';

class LinksExecutor {
  LinksExecutor({required LinkCreator linkCreator})
    : _pipeline = LinkPipeline(linkCreator);

  final LinkPipeline _pipeline;

  Future<int> runBuildLinks() async {
    _printHeader('Build Symlinks Creator');

    final context = await _pipeline.run(
      LinkContext(fileName: 'build.yaml', outputDir: 'yaml/builds'),
    );
    _reportSummary(context.summary!);
    return context.exitCode;
  }

  Future<int> runPubspecLinks() async {
    _printHeader('Pubspec Symlinks Creator');

    final context = await _pipeline.run(
      LinkContext(fileName: 'pubspec.yaml', outputDir: 'yaml/pubspecs'),
    );
    _reportSummary(context.summary!);
    return context.exitCode;
  }

  Future<int> runYamlLinks() async {
    Console.write('=== Pubspec Symlinks ===');
    final pubspecContext = await _pipeline.run(
      LinkContext(fileName: 'pubspec.yaml', outputDir: 'yaml/pubspecs'),
    );

    Console.write('\n=== Build Symlinks ===');
    final buildContext = await _pipeline.run(
      LinkContext(fileName: 'build.yaml', outputDir: 'yaml/builds'),
    );

    Console.write('\n=====================================');
    Console.success(
      '✓ Pubspec symlinks: ${pubspecContext.summary?.created ?? 0}, build symlinks: ${buildContext.summary?.created ?? 0}',
    );
    final failures = (pubspecContext.summary?.failed ?? 0) +
        (buildContext.summary?.failed ?? 0);
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
