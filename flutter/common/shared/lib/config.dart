import 'package:common_shared/src/utils/console.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class CommonSharedConfig {
  factory CommonSharedConfig() => _instance;
  CommonSharedConfig._();
  static final _instance = CommonSharedConfig._();

  Future<void> setup({
    required RemoteConfigSettings remoteConfigSettings,
    ConsoleFormatter? consoleFormatter,
  }) async {
    Console.formatter = consoleFormatter;

    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(remoteConfigSettings);
    await remoteConfig.fetchAndActivate();

    Console.log(
      '📡 Config values: ${remoteConfig.getAll().map((key, value) {
        return MapEntry(key, value.asString());
      })}\n',
    );
  }
}
