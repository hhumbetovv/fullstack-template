import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/feature/links/feature.dart';
import 'package:scripts/src/feature/links/services/link_creator.dart';

class YamlLinksCommand extends ScriptsCommand {
  YamlLinksCommand()
    : _orchestrator = LinksOrchestrator(linkCreator: const LinkCreator()),
      super(
        commandName: 'yaml-links',
        commandDescription:
            'Run both pubspec-links and build-links commands sequentially.',
      );

  final LinksOrchestrator _orchestrator;

  @override
  Future<int> runCommand() => _orchestrator.runYamlLinks();
}
