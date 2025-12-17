import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/core/config/scripts_config.dart';
import 'package:scripts/src/core/di/dependency_setup.dart';
import 'package:scripts/src/features/build_engine/features/codegen/commands/build/build_executor.dart';

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
        aliases: ['aab'],
      )
      ..addFlag(
        'android-apk',
        help: 'Only build the Android APK release artifact.',
        negatable: false,
        aliases: ['apk'],
      )
      ..addFlag(
        'ios-ipa',
        help: 'Only copy the iOS IPA archive when running release builds.',
        negatable: false,
        aliases: ['ipa'],
      )
      ..addFlag(
        'ios-app',
        help: 'Only copy the iOS .app bundle artifacts.',
        negatable: false,
        aliases: ['app'],
      )
      ..addMultiOption(
        'flavor',
        help:
            'Build only the specified flavor(s). Defaults to all flavors discovered from app/*.env*.',
        valueHelp: 'name',
        splitCommas: true,
      )
      ..addFlag(
        'release',
        help:
            'Include release builds. Enabled by default when no build mode filters are provided.',
        negatable: false,
      )
      ..addFlag(
        'debug',
        help:
            'Include debug builds. Enabled by default when no build mode filters are provided.',
        negatable: false,
      )
      ..addFlag(
        'obfuscate',
        help: 'Add --obfuscate to Android release builds.',
        defaultsTo: CodegenBuildConfig.obfuscateAndroid,
      )
      ..addFlag(
        'split-debug-info',
        help: 'Add --split-debug-info to Android release builds.',
        defaultsTo: CodegenBuildConfig.splitDebugInfo,
      )
      ..addOption(
        'split-debug-info-path',
        help: 'Directory used when --split-debug-info is enabled.',
        valueHelp: 'dir',
        defaultsTo: CodegenBuildConfig.splitDebugInfoPath,
      )
      ..addFlag(
        'apply-target-platform',
        help: 'Add --target-platform for Android builds.',
        defaultsTo: CodegenBuildConfig.applyTargetPlatform,
      )
      ..addOption(
        'target-platform',
        help: 'Value used for --target-platform when applied.',
        valueHelp: 'platforms',
        defaultsTo: CodegenBuildConfig.targetPlatform,
      );
  }

  @override
  Future<int> runCommand() {
    configureDependencies();
    return getDependency<BuildExecutor>().run(argResults);
  }
}
