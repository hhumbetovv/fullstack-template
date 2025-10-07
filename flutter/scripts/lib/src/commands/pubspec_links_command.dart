import 'package:args/command_runner.dart';

import 'package:scripts/src/common/console.dart';
import 'package:scripts/src/feature/links/link_creator.dart';

class PubspecLinksCommand extends Command<int> {
  PubspecLinksCommand();

  @override
  String get name => 'pubspec-links';

  @override
  String get description =>
      'Create symlinks for pubspec.yaml files under yaml/pubspecs.';

  @override
  Future<int> run() async {
    Console.write('=====================================');
    Console.write('    Pubspec Symlinks Creator');
    Console.write('=====================================');

    final summary = await createSymlinks(
      fileName: 'pubspec.yaml',
      outputDir: 'yaml/pubspecs',
    );

    Console.write('\n=====================================');
    Console.success('✓ Total symlinks created: ${summary.created}');
    if (summary.failed > 0) {
      Console.error('✗ Failed: ${summary.failed}');
    }
    Console.write('=====================================');

    if (summary.failed > 0) {
      return 1;
    }

    Console.success('Script completed successfully!');
    return 0;
  }
}
