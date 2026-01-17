import 'dart:ui';

extension StringX on String {
  Locale toLocale() {
    return Locale(split('.').first.split('_').first);
  }

  String? ifEmpty(String? value) {
    return isEmpty ? value : this;
  }

  bool match(RegExp exp) {
    return exp.hasMatch(this);
  }
}

extension NullableStringX on String? {
  bool isNullOrEmpty() {
    return this?.isEmpty ?? true;
  }
}
