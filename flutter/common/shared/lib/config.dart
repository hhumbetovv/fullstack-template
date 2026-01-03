import 'package:common_shared/public.dart';
import 'package:firebase_core/firebase_core.dart';
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

    final remoteConfig = FirebaseRemoteConfig.instanceFor(
      app: Firebase.app(
        Flavor.current.name,
      ),
    );
    await remoteConfig.setConfigSettings(remoteConfigSettings);
    await remoteConfig.fetchAndActivate();

    Console.isEnabled = Flavor.current == Flavor.dev || Environment.isBeta;

    Console.log(
      '📡 Config values: ${remoteConfig.getAll().map((key, value) {
        return MapEntry(key, value.asString());
      })}\n',
    );
  }
}
