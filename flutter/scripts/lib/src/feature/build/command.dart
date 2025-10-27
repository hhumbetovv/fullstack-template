import 'package:scripts/src/core/core.dart';

import 'build_feature.dart';

class BuildCommand extends ScriptsCommand {
  BuildCommand()
    : super(
        commandName: 'build',
        commandDescription:
            'Run bootstrap and produce Android/iOS artifacts across modes and flavors.',
      ) {
    argParser
      ..addFlag(
        'keep-key-properties',
        help: 'Keep the generated android/key.properties file after the build.',
        negatable: false,
      )
      ..addFlag(
        'android-aab',
        help: 'Only build the Android App Bundle release artifact.',
        negatable: false,
      )
      ..addFlag(
        'android-apk',
        help: 'Only build the Android APK release artifact.',
        negatable: false,
      )
      ..addFlag(
        'obfuscate',
        help: 'Add --obfuscate to Android release builds.',
        defaultsTo: true,
      )
      ..addFlag(
        'split-debug-info',
        help: 'Add --split-debug-info to Android release builds.',
        defaultsTo: true,
      )
      ..addOption(
        'split-debug-info-path',
        help: 'Directory used when --split-debug-info is enabled.',
        valueHelp: 'dir',
        defaultsTo: './android/app/release',
      )
      ..addFlag(
        'apply-target-platform',
        help: 'Add --target-platform for Android builds.',
        defaultsTo: true,
      )
      ..addOption(
        'target-platform',
        help: 'Value used for --target-platform when applied.',
        valueHelp: 'platforms',
        defaultsTo: 'android-arm,android-arm64,android-x64',
      );
  }

  @override
  Future<int> runCommand() => runBuildFeature(argResults);
}
