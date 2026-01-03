const String? flavor = String.fromEnvironment('FLAVOR') != '' ? String.fromEnvironment('FLAVOR') : null;

enum Flavor {
  prod,
  dev
  ;

  static Flavor get current {
    return Flavor.values.firstWhere(
      (element) => element.name == flavor?.toLowerCase(),
      orElse: () => Flavor.prod,
    );
  }

  String get file => '.env.$name';
}
