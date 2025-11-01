import 'package:scripts/src/application/locale/locale_executor.dart';
import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/core/di/dependency_setup.dart';

class LocaleCommand extends ScriptsCommand {
  LocaleCommand()
    : super(
        commandName: 'locale',
        commandDescription:
            'Generate locale key constants from translation JSON files.',
      ) {
    argParser
      ..addOption(
        'input',
        defaultsTo: 'app/assets/translations',
        help: 'Directory containing translation JSON files.',
      )
      ..addOption(
        'output',
        defaultsTo: 'common/lib/src/constants/locale_keys.dart',
        help: 'Path for the generated Dart file.',
      );
  }

  @override
  Future<int> runCommand() async {
    final inputPath =
        argResults?['input'] as String? ?? 'app/assets/translations';
    final outputPath =
        argResults?['output'] as String? ??
        'common/lib/src/constants/locale_keys.dart';
    configureDependencies();
    return getDependency<LocaleExecutor>().run(
      inputPath: inputPath,
      outputPath: outputPath,
    );
  }
}
