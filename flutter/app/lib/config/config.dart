import 'package:app/config/injectable.dart';
import 'package:common_shared/config.dart';
import 'package:common_shared/environment.dart';
import 'package:common_shared/utils.dart';
import 'package:intl/intl.dart';

final class AppConfig {
  static Future<void> setup() async {
    CommonSharedConfig().setup(
      consoleFormatter: ([dateFormat, date]) {
        return DateFormat(dateFormat).format(date ?? DateTime.now());
      },
    );
    Console.isEnabled = true;
    await Environment.initialize();
    await configureDependencies();
  }
}
