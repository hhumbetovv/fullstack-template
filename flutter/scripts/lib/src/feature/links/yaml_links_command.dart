import 'package:scripts/src/core/core.dart';

import 'links_feature.dart';

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
