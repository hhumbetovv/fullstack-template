import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/core/di/dependency_setup.dart';
import 'package:scripts/src/features/links/commands/links_executor.dart';

class YamlLinksCommand extends ScriptsCommand {
  YamlLinksCommand()
    : super(
        commandName: 'yaml-links',
        commandDescription:
            'Run both pubspec-links and build-links commands sequentially.',
      );

  @override
  Future<int> runCommand() {
    configureDependencies();
    return getDependency<LinksExecutor>().runYamlLinks();
  }
}
