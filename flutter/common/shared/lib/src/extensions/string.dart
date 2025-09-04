import 'dart:ui';

extension StringExt on String {
  Locale toLocale() {
    return Locale(split('.').first.split('_').first);
  }

  String? ifEmpty(String? value) {
    return isEmpty ? value : this;
  }
}
