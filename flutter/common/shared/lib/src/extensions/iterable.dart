import 'package:common_shared/src/constants/types.dart';

extension IterableX<T> on Iterable<T> {
  List<R> mapToList<R>(ElementMapper<T, R> toElement) {
    return map(toElement).toList();
  }
}
