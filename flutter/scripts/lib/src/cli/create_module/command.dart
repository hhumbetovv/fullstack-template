import 'package:args/command_runner.dart';
import 'package:scripts/src/application/module_create/module_create_executor.dart';
import 'package:scripts/src/application/module_graph/module_graph_executor.dart';
import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/core/di/dependency_setup.dart';
import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/domain/models/module_graph_options.dart';

class CreateModuleCommand extends ScriptsCommand {
  CreateModuleCommand()
    : super(
        commandName: 'create-module',
        commandDescription:
            'Scaffold a feature module and refresh the module graph.',
        aliases: const ['create'],
      );

  @override
  Future<int> runCommand() async {
    final rest = argResults?.rest ?? const [];
    if (rest.length != 2) {
      throw UsageException(
        'Expected <feature-path> and <module-type>. Example: create-module profile data_api',
        usage,
      );
    }

    final featurePath = rest[0];
    final moduleType = rest[1];

    configureDependencies();

    final createResult = await getDependency<ModuleCreateExecutor>().run(
      featurePath: featurePath,
      moduleType: moduleType,
    );
    if (createResult != 0) {
      return createResult;
    }

    Console.info('Module created. Regenerating module graph...');
    final graphResult = await getDependency<ModuleGraphExecutor>().run(
      const ModuleGraphOptions(verbose: false, maxParallelBuilds: 4),
    );
    if (graphResult == 0) {
      Console.success('Module graph updated.');
    }
    return graphResult;
  }
}
