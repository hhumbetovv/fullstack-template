export 'package:meta/meta.dart' show immutable, internal, protected;

final class Data {
  const Data();
}

const data = Data();

final class Default<T> {
  const Default(this.data);

  final T data;
}
