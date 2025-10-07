import 'package:args/command_runner.dart';

import 'package:scripts/src/common/console.dart';
import 'package:scripts/src/feature/links/link_creator.dart';

class BuildLinksCommand extends Command<int> {
  BuildLinksCommand();

  @override
  String get name => 'build-links';

  @override
  String get description =>
      'Create symlinks for build.yaml files under yaml/builds.';

  @override
  Future<int> run() async {
    Console.write('=====================================');
    Console.write('    Build Symlinks Creator');
    Console.write('=====================================');

    final summary = await createSymlinks(
      fileName: 'build.yaml',
      outputDir: 'yaml/builds',
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
