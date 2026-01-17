import 'package:flutter/foundation.dart';

@immutable
final class ResultEntry<T extends Object> {
  const ResultEntry({
    required this.value,
    required this.timestamp,
  });

  final T value;
  final int timestamp;
}
