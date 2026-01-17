import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/core/di/dependency_setup.dart';
import 'package:scripts/src/features/links/commands/links_executor.dart';

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
