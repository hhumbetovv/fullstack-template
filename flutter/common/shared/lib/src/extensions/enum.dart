extension ListEnumX<T extends Enum> on List<T> {
  T? fromString(String? value) {
    if (value == null) return null;
    for (var i = 0; i < length; i++) {
      final element = this[i];
      if (element.name.toLowerCase() == value.toLowerCase()) {
        return element;
      }
    }
    return null;
  }
}
