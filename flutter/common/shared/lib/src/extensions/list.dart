typedef EntryMapper<T, R> = R Function(int index, T e);

extension ListX<T> on List<T> {
  List<R> mapIndexed<R>(EntryMapper<T, R> toElement) {
    return asMap().entries.map((entry) {
      return toElement(
        entry.key,
        entry.value,
      );
    }).toList();
  }
}
