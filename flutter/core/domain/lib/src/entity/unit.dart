final class Unit {
  factory Unit() => _instance;

  factory Unit.fromJson(Map<String, dynamic> _) => _instance;

  const Unit._();

  static const _instance = Unit._();

  static Map<void, void> toJson() => {};

  @override
  String toString() {
    return 'Unit';
  }
}
