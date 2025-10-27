import '../../core/core.dart';
import '../../services/build_runner_service.dart';
import '../../services/workspace_service.dart';

Future<int> runGenBuildFeature(Iterable<String> moduleFilters) async {
  final modules = await discoverModules(includeNonBuildRunner: true);
  if (modules.isEmpty) {
    Console.error('No modules discovered. Are you in the repository root?');
    return 1;
  }

  final targets = <ModuleInfo>[];

  if (moduleFilters.isEmpty) {
    targets.addAll(modules.where((module) => module.hasBuildRunner));
    Console.info('Building all modules with build_runner...');
  } else {
    Console.info('Building selected modules: ${moduleFilters.join(', ')}');
    for (final filter in moduleFilters) {
      final module = findModule(modules, filter);
      if (module == null) {
        Console.warning(
          "Module '$filter' not found by name or path, skipping...",
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
    final result = await runBuildRunnerCommand(
      module.directory,
      ['build', '-d'],
    );
    if (result.exitCode == 0) {
      Console.success('✅ Build complete for ${module.name}');
    } else {
      hasFailures = true;
      Console.error('❌ Build failed for ${module.name}');
    }
  }

  Console.write('\n🎉 Build process completed!');
  return hasFailures ? 1 : 0;
}
