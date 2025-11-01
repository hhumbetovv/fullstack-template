import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/feature/links/feature.dart';

class YamlLinksCommand extends ScriptsCommand {
  YamlLinksCommand()
    : super(
        commandName: 'yaml-links',
        commandDescription:
            'Run both pubspec-links and build-links commands sequentially.',
      );

  @override
  Future<int> runCommand() => runYamlLinksFeature();
}
