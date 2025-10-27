import 'dart:io';

class Console {
  static const String _red = '\x1b[0;31m';
  static const String _green = '\x1b[0;32m';
  static const String _yellow = '\x1b[1;33m';
  static const String _blue = '\x1b[0;34m';
  static const String _reset = '\x1b[0m';

  static void info(String message) => _print(_blue, message);
  static void success(String message) => _print(_green, message);
  static void warning(String message) => _print(_yellow, message);
  static void error(String message) => _print(_red, message);

  static void write(String message) => stdout.writeln(message);

  static void _print(String color, String message) {
    stdout.writeln('$color$message$_reset');
  }
}
