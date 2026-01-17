import 'dart:async';
import 'dart:io';

bool _isUnsupportedOnPlatform(ProcessSignal signal) {
  // Windows does not support listening for many POSIX signals like SIGTERM.
  if (Platform.isWindows) {
    try {
      if (identical(signal, ProcessSignal.sigterm)) return true;
    } on Object catch (_) {
      return true;
    }
  }
  return false;
}

/// Attempts to listen for [signal] and quietly skips unsupported ones.
/// On platforms where a signal cannot be watched, this returns null.
/// Also guards against stream errors from `signal.watch()`.
StreamSubscription<ProcessSignal>? listenForSignal(
  ProcessSignal signal,
  void Function(ProcessSignal event) onData,
) {
  if (_isUnsupportedOnPlatform(signal)) {
    return null;
  }

  try {
    final sub = signal.watch().listen(
      onData,
      onError: (_) {
        // Swallow unsupported signal stream errors (e.g., Windows SIGTERM).
      },
      cancelOnError: true,
    );
    return sub;
  } on SignalException {
    return null;
  } on Object {
    return null;
  }
}
