import 'dart:async';
import 'dart:collection';
import 'dart:developer' as dev;

import 'package:common_shared/public.dart';

typedef LogEntry = ({String message, AnsiColors color, DateTime timestamp, String tag});
typedef ConsoleFormatter = String Function([String? dateFormat, DateTime? date]);

sealed class Console {
  static String dateFormat = 'HH:mm:ss.SSS';
  static ConsoleFormatter? formatter;

  static late bool isEnabled;
  static int historyLimit = 1000;

  static final Queue<LogEntry> _logQueue = Queue<LogEntry>();
  static bool _isProcessing = false;

  static final List<LogEntry> _history = [];
  static List<LogEntry> get history => List.unmodifiable(_history);

  static final List<String> _tags = [];
  static List<String> get tags => _tags.where((tag) => tag.isNotEmpty).toList();

  static void log(String message, [AnsiColors color = AnsiColors.blue, String tag = '']) {
    if (!isEnabled) return;
    _enqueueLog(message, color, tag);
  }

  static void print(dynamic message, [AnsiColors color = AnsiColors.blue]) {
    log('📌 $message\n');
  }

  static String now([String? dateFormat, DateTime? date]) {
    return formatter?.call(dateFormat, date) ?? date.toString();
  }

  static void _enqueueLog(
    String message,
    AnsiColors color,
    String tag,
  ) {
    if (!isEnabled) return;

    if (!_tags.contains(tag)) {
      _tags.add(tag);
    }

    final logEntry = (
      message: message,
      color: color,
      timestamp: DateTime.now(),
      tag: tag,
    );

    _logQueue.add(logEntry);
    _processQueue();

    _history.insert(0, logEntry);
    if (_history.length > historyLimit) {
      _history.removeAt(0);
    }
  }

  static void firebaseLog(String log) {
    // FirebaseCrashlytics.instance.log(log),
  }

  static void firebaseRecordError(
    dynamic exception,
    StackTrace? trace, {
    dynamic reason,
  }) {
    // FirebaseCrashlytics.instance.recordError(
    //   exception,
    //   trace,
    //   reason,
    // ),
  }

  static Future<void> _processQueue() async {
    if (_isProcessing || _logQueue.isEmpty) return;

    _isProcessing = true;

    while (_logQueue.isNotEmpty) {
      final logEntry = _logQueue.removeFirst();
      _processLog(logEntry);

      final delay = _calculateDelay(logEntry.message.length);
      await Future.delayed(delay, () {});
    }

    _isProcessing = false;
  }

  static Duration _calculateDelay(int messageLength) {
    const baseDelay = 5;
    const delayPer100Chars = 2;
    const maxDelay = 100;

    final delayMs = (baseDelay + (messageLength ~/ 100) * delayPer100Chars).clamp(baseDelay, maxDelay);
    return Duration(milliseconds: delayMs);
  }

  static void _processLog(LogEntry entry) {
    dev.log(
      '${entry.color.code}${entry.message}${AnsiColors.kDefault.code}',
      name: now(dateFormat, entry.timestamp),
    );
  }

  static void clearLogs() {
    _history.clear();
    _tags.clear();
  }

  static List<String> exportLogsAsStrings() {
    return _history.map((log) {
      return '[${now(dateFormat, log.timestamp)}]: ${log.message}';
    }).toList();
  }
}
