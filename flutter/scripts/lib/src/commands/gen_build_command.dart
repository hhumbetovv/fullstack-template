import 'package:args/command_runner.dart';

import 'package:scripts/src/common/build_runner.dart';
import 'package:scripts/src/common/console.dart';
import 'package:scripts/src/common/workspace.dart';

class GenBuildCommand extends Command<int> {
  GenBuildCommand();

  @override
  String get name => 'gen-build';

  @override
  String get description =>
      'Run build_runner build for modules that depend on it.';

  @override
  Future<int> run() async {
    final modules = await discoverModules(includeNonBuildRunner: true);
    if (modules.isEmpty) {
      Console.error('No modules discovered. Are you in the repository root?');
      return 1;
    }

    final targets = <ModuleInfo>[];
    final rest = argResults?.rest ?? <String>[];

    if (rest.isEmpty) {
      targets.addAll(modules.where((module) => module.hasBuildRunner));
      Console.info('Building all modules with build_runner...');
    } else {
      Console.info('Building selected modules: ${rest.join(', ')}');
      for (final target in rest) {
        final module = findModule(modules, target);
        if (module == null) {
          Console.warning(
            "Module '$target' not found by name or path, skipping...",
          );
          continue;
        }
        if (!module.hasBuildRunner) {
          Console.warning(
            "Module '${module.name}' does not depend on build_runner, skipping...",
          );
          continue;
        }
        targets.add(module);
      }
    }

    if (targets.isEmpty) {
      Console.warning('No matching modules to build.');
      return 0;
    }

    var hasFailures = false;

    for (final module in targets) {
      Console.write('\n🔨 Building ${module.name} (${module.path})');
      final exitCode = await runBuildRunnerCommand(
        module.directory,
        ['build', '-d'],
      );
      if (exitCode == 0) {
        Console.success('✅ Build complete for ${module.name}');
      } else {
        hasFailures = true;
        Console.error('❌ Build failed for ${module.name}');
      }
    }

    Console.write('\n🎉 Build process completed!');
    return hasFailures ? 1 : 0;
  }
}
