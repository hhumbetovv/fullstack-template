import 'package:app/config/firebase_options.dart';
import 'package:app/config/injectable.dart';
import 'package:common_presentation/config.dart';
import 'package:common_shared/config.dart';
import 'package:common_shared/exports.dart';
import 'package:common_shared/public.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ui_components/public.dart';
import 'package:ui_foundation/public.dart';

final class AppConfig {
  static Future<void> setup() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Environment.initialize();

    await Firebase.initializeApp(
      name: Flavor.current.name,
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      Flavor.current == Flavor.prod && kReleaseMode,
    );

    await CommonSharedConfig().setup(
      remoteConfigSettings: RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const AppDuration.zero(),
      ),
      consoleFormatter: ([dateFormat, date]) {
        return DateFormat(dateFormat).format(date ?? DateTime.now());
      },
    );

    CommonPresentationConfig.setup(
      snackBarBuilder: (message, type) {
        final bgColor = switch (type) {
          MessageType.success => AppColors.green100,
          MessageType.info => AppColors.blue100,
          MessageType.error => AppColors.red100,
        };
        return SnackBar(
          duration: const AppDuration.snackBar(),
          showCloseIcon: true,
          closeIconColor: AppColors.white,
          backgroundColor: bgColor,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.small(),
          ),
          margin: const AppPadding.base(),
          behavior: SnackBarBehavior.floating,
          content: UiText(
            message,
            color: AppColors.white,
          ),
        );
      },
    );

    await configureDependencies();
  }
}
