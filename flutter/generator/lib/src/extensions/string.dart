extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String uncapitalize() {
    return '${this[0].toLowerCase()}${substring(1)}';
  }

  String normalize() {
    return replaceAll('_', '');
  }

  String extract(String from, String to) {
    final lastIndex = lastIndexOf(to);
    final firstIndex = indexOf(from) + 1;
    return substring(firstIndex, lastIndex);
  }

  String trimBefore(String to) {
    return substring(0, toLowerCase().indexOf(to.toLowerCase()));
  }

  String trimAfter(String from) {
    return substring(toLowerCase().indexOf(from.toLowerCase()) + 1);
  }
}
