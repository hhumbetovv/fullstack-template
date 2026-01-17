import 'package:common_shared/src/constants/types.dart';
import 'package:common_shared/src/extensions/iterable.dart';

extension ListX<T> on List<T> {
  List<R> mapIndexed<R>(EntryMapper<T, R> toElement) {
    return asMap().entries.mapToList((entry) {
      return toElement(
        entry.key,
        entry.value,
      );
    });
  }

  List<R> mapToList<R>(ElementMapper<T, R> toElement) {
    return map(toElement).toList();
  }
}
