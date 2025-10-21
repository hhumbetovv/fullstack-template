import 'dart:collection';

String toLowerCamel(String input) {
  final parts = input
      .replaceAll(r'\', '/')
      .split(RegExp('[^A-Za-z0-9]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part.toLowerCase())
      .toList();

  if (parts.isEmpty) {
    return 'value';
  }

  final first = parts.first;
  final rest = parts.skip(1).map((part) => part[0].toUpperCase() + part.substring(1)).join();

  final candidate = '$first$rest';

  if (RegExp(r'^\d').hasMatch(candidate)) {
    return 'value${candidate[0].toUpperCase()}${candidate.substring(1)}';
  }

  return candidate;
}

class NameRegistry {
  final Map<String, int> _used = HashMap<String, int>();

  String allocate(String candidate, {required String prefix}) {
    final name = candidate.isEmpty ? prefix : candidate;

    final count = _used.update(name, (value) => value + 1, ifAbsent: () => 0);
    if (count == 0) {
      return name;
    }

    return '$name$count';
  }
}
