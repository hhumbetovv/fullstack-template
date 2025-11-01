import 'package:scripts/src/core/state/build_state.dart';

class Colors {
  static const String red = '\x1b[0;31m';
  static const String green = '\x1b[0;32m';
  static const String yellow = '\x1b[1;33m';
  static const String blue = '\x1b[0;34m';
  static const String purple = '\x1b[0;35m';
  static const String cyan = '\x1b[0;36m';
  static const String gray = '\x1b[0;90m';
  static const String nc = '\x1b[0m';
}

// ignore: avoid_print
void log(dynamic data) => print(data);

sealed class Logger {
  static void info(String message) {
    log('${Colors.blue}ℹ️  $message${Colors.nc}');
  }

  static void success(String message) {
    log('${Colors.green}✅ $message${Colors.nc}');
  }

  static void warning(String message) {
    log('${Colors.yellow}⚠️  $message${Colors.nc}');
  }

  static void error(String message) {
    log('${Colors.red}❌ $message${Colors.nc}');
  }

  static void building(String message) {
    log('${Colors.purple}🔨 $message${Colors.nc}');
  }

  static void debug(String message) {
    if (state.verbose) {
      log('${Colors.gray}🔍 DEBUG: $message${Colors.nc}');
    }
  }

  static void verbose(String message) {
    if (state.verbose) {
      log('${Colors.cyan}   → $message${Colors.nc}');
    }
  }
}
