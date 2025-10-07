import 'package:args/command_runner.dart';

import 'package:scripts/src/common/build_runner.dart';
import 'package:scripts/src/common/console.dart';
import 'package:scripts/src/common/workspace.dart';

class GenCleanCommand extends Command<int> {
  GenCleanCommand();

  @override
  String get name => 'gen-clean';

  @override
  String get description =>
      'Run build_runner clean for all modules with build_runner.';

  @override
  Future<int> run() async {
    final modules = await discoverModules(includeNonBuildRunner: false);
    if (modules.isEmpty) {
      Console.warning('No modules with build_runner were found.');
      return 0;
    }

    Console.write('🚀 Cleaning generated files');

    var hasFailures = false;
    for (final module in modules) {
      Console.write('🧹 ${module.path}');
      final exitCode = await runBuildRunnerCommand(module.directory, ['clean']);
      if (exitCode != 0) {
        hasFailures = true;
        Console.error('Failed to clean ${module.name}.');
      }
    }

    Console.write('\n🧹 Removing generated artifacts');
    deleteGeneratedArtifacts();

    if (hasFailures) {
      Console.error('Some clean steps failed.');
      return 1;
    }

    Console.success('✅ All cleanups completed');
    return 0;
  }
}
