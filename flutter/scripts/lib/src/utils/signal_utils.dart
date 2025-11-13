import 'dart:async';
import 'dart:io';

/// Attempts to listen for [signal] and quietly skips unsupported ones.
StreamSubscription<ProcessSignal>? listenForSignal(
  ProcessSignal signal,
  void Function(ProcessSignal event) onData,
) {
  try {
    return signal.watch().listen(onData);
  } on SignalException {
    return null;
  } on Object {
    return null;
  }
}
