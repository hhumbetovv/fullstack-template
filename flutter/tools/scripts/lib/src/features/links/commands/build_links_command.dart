import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/core/di/dependency_setup.dart';
import 'package:scripts/src/features/links/commands/links_executor.dart';

class BuildLinksCommand extends ScriptsCommand {
  BuildLinksCommand()
    : super(
        commandName: 'build-links',
        commandDescription:
            'Create symlinks for build.yaml files under yaml/builds.',
      );

  @override
  Future<int> runCommand() {
    configureDependencies();
    return getDependency<LinksExecutor>().runBuildLinks();
  }
}
