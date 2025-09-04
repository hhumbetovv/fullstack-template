import 'package:flutter_dotenv/flutter_dotenv.dart';

final class Environment {
  static Future<void> initialize() async {
    await dotenv.load(fileName: Flavor.current.file);
  }

  static String baseUrl = dotenv.env['BASE_URL'] ?? '';
}

const String? flavor = String.fromEnvironment('FLAVOR') != '' ? String.fromEnvironment('FLAVOR') : null;

enum Flavor {
  prod,
  dev;

  static Flavor get current {
    return Flavor.values.firstWhere(
      (element) => element.name == flavor?.toLowerCase(),
      orElse: () => Flavor.prod,
    );
  }

  String get file => '.env.$name';
}
