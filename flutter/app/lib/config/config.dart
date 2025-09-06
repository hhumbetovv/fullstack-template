import 'package:common_shared/config.dart';
import 'package:intl/intl.dart';

final class AppConfig {
  static Future<void> setup() async {
    CommonSharedConfig().setup(
      consoleFormatter: ([dateFormat, date]) {
        return DateFormat(dateFormat).format(date ?? DateTime.now());
      },
    );
  }
}
