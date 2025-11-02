import 'package:app/config/injectable.dart';
import 'package:common_presentation/config.dart';
import 'package:common_shared/config.dart';
import 'package:common_shared/environment.dart';
import 'package:common_shared/public.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ui_components/public.dart';
import 'package:ui_foundation/public.dart';

final class AppConfig {
  static Future<void> setup() async {
    CommonSharedConfig().setup(
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
    Console.isEnabled = Flavor.current == Flavor.dev;
    await Environment.initialize();
    await configureDependencies();
  }
}
