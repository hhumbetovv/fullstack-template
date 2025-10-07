import 'package:args/command_runner.dart';

import 'package:scripts/src/common/console.dart';
import 'package:scripts/src/feature/links/link_creator.dart';

class YamlLinksCommand extends Command<int> {
  YamlLinksCommand();

  @override
  String get name => 'yaml-links';

  @override
  String get description =>
      'Run both pubspec-links and build-links commands sequentially.';

  @override
  Future<int> run() async {
    Console.write('=== Pubspec Symlinks ===');
    final pubspecSummary = await createSymlinks(
      fileName: 'pubspec.yaml',
      outputDir: 'yaml/pubspecs',
    );

    Console.write('\n=== Build Symlinks ===');
    final buildSummary = await createSymlinks(
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
}
