import 'package:scripts/src/application/links/links_executor.dart';
import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/core/di/dependency_setup.dart';

class PubspecLinksCommand extends ScriptsCommand {
  PubspecLinksCommand()
    : super(
        commandName: 'pubspec-links',
        commandDescription:
            'Create symlinks for pubspec.yaml files under yaml/pubspecs.',
      );

  @override
  Future<int> runCommand() {
    configureDependencies();
    return getDependency<LinksExecutor>().runPubspecLinks();
  }
}
