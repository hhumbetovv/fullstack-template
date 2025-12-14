import 'package:firebase_remote_config/firebase_remote_config.dart';

enum ConfigKeys {
  minRequiredBuild('min_required_build'),
  androidStoreUrl('android_store_url'),
  iosStoreUrl('ios_store_url'),
  ;

  const ConfigKeys(this.key);

  final String key;

  String get readAsString => FirebaseRemoteConfig.instance.getString(key);
  int get readAsInt => FirebaseRemoteConfig.instance.getInt(key);
}
