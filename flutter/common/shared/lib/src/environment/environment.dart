import 'package:common_shared/public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final class Environment {
  static Future<void> initialize() async {
    await dotenv.load(fileName: Flavor.current.file);
  }

  static String baseUrl = dotenv.env['BASE_URL'] ?? '';

  //! Firebase
  static String firebaseProjectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String firebaseMessagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String firebaseStorageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
  static String firebaseAndroidApiKey = dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? '';
  static String firebaseIOSApiKey = dotenv.env['FIREBASE_IOS_API_KEY'] ?? '';
  static String firebaseAndroidAppId = dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? '';
  static String firebaseIOSAppId = dotenv.env['FIREBASE_IOS_APP_ID'] ?? '';
  static String firebaseIOSBundleId = dotenv.env['FIREBASE_IOS_BUNDLE_ID'] ?? '';

  static bool get isBeta {
    final isBetaFlavor = Flavor.current == Flavor.beta;
    final isBetaRemotely = ConfigKeys.isBetaEnabled.readAsBool;
    return isBetaFlavor && isBetaRemotely;
  }
}
