import 'package:common_shared/public.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Unsupported Firebase platform');
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError('Unsupported Firebase platform'),
    };
  }

  static FirebaseOptions android = FirebaseOptions(
    projectId: Environment.firebaseProjectId,
    messagingSenderId: Environment.firebaseMessagingSenderId,
    storageBucket: Environment.firebaseStorageBucket,
    apiKey: Environment.firebaseAndroidApiKey,
    appId: Environment.firebaseAndroidAppId,
  );

  static FirebaseOptions ios = FirebaseOptions(
    projectId: Environment.firebaseProjectId,
    messagingSenderId: Environment.firebaseMessagingSenderId,
    storageBucket: Environment.firebaseStorageBucket,
    apiKey: Environment.firebaseIOSApiKey,
    appId: Environment.firebaseIOSAppId,
    iosBundleId: Environment.firebaseIOSBundleId,
  );
}
