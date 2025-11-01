import 'package:scripts/src/application/links/links_executor.dart';
import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/core/di/dependency_setup.dart';

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
