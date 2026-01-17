abstract class Identifiable {
  abstract final String id;
}

extension ListIdentifiableExt<T extends Identifiable> on List<T> {
  List<T> addUniques(List<T> other) {
    return this +
        other.where((otherElement) {
          return every((element) {
            return element.id != otherElement.id;
          });
        }).toList();
  }
}
