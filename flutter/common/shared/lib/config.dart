import 'package:common_shared/src/utils/console.dart';

class CommonSharedConfig {
  factory CommonSharedConfig() => _instance;
  CommonSharedConfig._();
  static final _instance = CommonSharedConfig._();

  void setup({
    ConsoleFormatter? consoleFormatter,
  }) {
    Console.formatter = consoleFormatter;
  }
}
