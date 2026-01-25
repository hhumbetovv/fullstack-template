import 'dart:io';

import 'package:package_config/package_config.dart';

class PackageResolver {
  PackageResolver() : _packageConfigFuture = _loadPackageConfig();

  final Future<PackageConfig> _packageConfigFuture;

  Future<Package> resolve(String packageName) async {
    final config = await _packageConfigFuture;
    return config.packages.firstWhere(
      (pkg) => pkg.name == packageName,
      orElse: () => throw StateError(
        'Package "$packageName" was not found in package_config.json.',
      ),
    );
  }

  static Future<PackageConfig> _loadPackageConfig() async {
    final packageConfig = await findPackageConfig(Directory.current);
    if (packageConfig == null) {
      throw StateError(
        'Unable to locate package_config.json for asset builder.',
      );
    }

    return packageConfig;
  }
}
