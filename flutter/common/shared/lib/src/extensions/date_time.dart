import 'package:intl/intl.dart';

extension DateTimeX on DateTime? {
  String formatToFieldValue() {
    final value = this;
    if (value == null) return '';
    return DateFormat('dd/MM/yyyy').format(value);
  }
}
