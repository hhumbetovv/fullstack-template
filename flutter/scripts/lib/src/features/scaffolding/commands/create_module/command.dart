import 'package:args/command_runner.dart';
import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/core/di/dependency_setup.dart';
import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/features/scaffolding/commands/create_module/module_create_executor.dart';

class CreateModuleCommand extends ScriptsCommand {
  CreateModuleCommand()
    : super(
        commandName: 'create-module',
        commandDescription: 'Scaffold a feature module.',
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

    Console.success(
      'Module ready. Run `fvms pub-sync` to update the workspace.',
    );
    return 0;
  }
}
