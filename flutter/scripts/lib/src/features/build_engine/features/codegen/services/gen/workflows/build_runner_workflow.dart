import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/features/build_engine/domain/models/module_descriptor.dart';
import 'package:scripts/src/features/build_engine/features/codegen/ports/build_runner_port.dart';

class BuildRunnerWorkflow {
  const BuildRunnerWorkflow(this._buildRunner);

  final BuildRunnerPort _buildRunner;

  Future<int> execute(List<ModuleDescriptor> modules) async {
    if (modules.isEmpty) {
      Console.warning('No matching modules to build.');
      return 0;
    }

    var hasFailures = false;

    for (final module in modules) {
      Console.write('\n🔨 Building ${module.name} (${module.path})');
      final result = await _buildRunner.runCommand(
        module.directory,
        const ['build', '-d'],
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
}
