import 'dart:async';

class Debounce {
  Debounce({
    required this.milliseconds,
    this.action,
  });

  final int milliseconds;
  void Function()? action;
  Timer? _timer;

  void call(void Function() action, {bool immediately = false}) {
    _timer?.cancel();
    if (immediately) {
      action();
    } else {
      _timer = Timer(
        Duration(milliseconds: milliseconds),
        action,
      );
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
