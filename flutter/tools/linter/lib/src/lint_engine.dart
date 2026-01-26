import 'dart:io';

import 'package:feature_layer_linter/src/module_config.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

class Violation {
  const Violation({
    required this.package,
    required this.file,
    required this.line,
    required this.message,
  });

  final String package;
  final String file;
  final int line;
  final String message;

  String render() => '$package: $file:$line: \x1B[31mERROR:\x1B[0m $message';
}

class LintEngine {
  const LintEngine({
    required this.root,
    this.verbose = false,
  });

  final Directory root;
  final bool verbose;

  Future<List<Violation>> run() async {
    final packages = await _discoverPackages(root);
    if (verbose) {
      stdout.writeln('Discovered ${packages.length} packages');
    }

    final targetPackages = packages.where(_hasFeatureFolders).toList();
    if (verbose) {
      final featureLikePackages = targetPackages.map((package) {
        return package.name;
      });
      stdout.writeln('Feature-like packages: ${featureLikePackages.join(', ')}');
    }

    final all = <Violation>[];
    for (final package in targetPackages) {
      if (verbose) {
        stdout.writeln('Checking package: ${package.name} at ${package.dir.path}');
      }
      all.addAll(await _checkPackage(package));
    }
    return all;
  }

  Future<List<_Package>> _discoverPackages(Directory start) async {
    final packages = <_Package>[];
    final ignored = {
      '.git',
      '.dart_tool',
      'build',
      '.idea',
      '.vscode',
      '.misc',
    };

    await for (final entity in start.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (path.basename(entity.path) != 'pubspec.yaml') continue;

      final packageDir = entity.parent;
      final parts = path.split(path.relative(packageDir.path, from: start.path));
      if (parts.any(ignored.contains)) continue;

      final yaml = loadYaml(await entity.readAsString());
      final name = yaml['name']?.toString();
      if (name == null || name.isEmpty) continue;
      packages.add(_Package(name: name, dir: packageDir));
    }
    return packages;
  }

  bool _hasFeatureFolders(_Package package) {
    final libDir = Directory(path.join(package.dir.path, 'lib'));
    final hasData = Directory(
      path.join(libDir.path, 'src', 'data'),
    ).existsSync();
    final hasDomain = Directory(
      path.join(libDir.path, 'src', 'domain'),
    ).existsSync();
    final hasPresentation = Directory(
      path.join(libDir.path, 'src', 'presentation'),
    ).existsSync();

    return hasData || hasDomain || hasPresentation;
  }

  Future<List<Violation>> _checkPackage(_Package package) async {
    final violations = <Violation>[];
    final libDir = Directory(path.join(package.dir.path, 'lib'));
    final layerDirs = <String, String>{
      'data': path.join(libDir.path, 'src', 'data'),
      'domain': path.join(libDir.path, 'src', 'domain'),
      'presentation': path.join(libDir.path, 'src', 'presentation'),
    };

    try {
      package.lintRules ??= loadModuleLintRules(
        workspaceRoot: root,
        moduleDirectory: package.dir,
      );
    } on FormatException catch (error) {
      final modulePath = path.relative(
        path.join(package.dir.path, 'module.yaml'),
        from: root.path,
      );
      violations.add(
        Violation(
          package: package.name,
          file: modulePath,
          line: 1,
          message: 'Failed to load lint config: ${error.message}',
        ),
      );
      return violations;
    }

    for (final entry in layerDirs.entries) {
      final layer = entry.key;
      final dirPath = entry.value;
      final dir = Directory(dirPath);
      if (!dir.existsSync()) continue;

      await for (final file in dir.list(recursive: true, followLinks: false)) {
        if (file is! File) continue;
        if (!file.path.endsWith('.dart')) continue;
        final base = path.basename(file.path);
        if (base.endsWith('.g.dart') || base.endsWith('.freezed.dart')) continue;

        final text = await file.readAsString();
        final lines = text.split('\n');
        final importRe = RegExp('^\\s*import\\s+["\']([^"\']+)["\'];?', multiLine: true);
        for (final match in importRe.allMatches(text)) {
          final uri = match.group(1)!;
          final line = _lineForOffset(lines, match.start);
          final violation = _validateImport(package, layer, uri);
          if (violation != null) {
            violations.add(
              Violation(
                package: package.name,
                file: path.relative(file.path, from: root.path),
                line: line,
                message: violation,
              ),
            );
          }
        }
      }
    }

    return violations;
  }

  int _lineForOffset(List<String> lines, int offset) {
    var count = 0;
    for (var i = 0; i < lines.length; i++) {
      count += lines[i].length + 1;
      if (count > offset) return i + 1;
    }
    return lines.length;
  }

  String? _validateImport(_Package package, String layer, String uri) {
    if (uri.startsWith('./') || uri.startsWith('../')) {
      return 'Relative imports are not allowed under lib/$layer (use package:${package.name}/$layer.dart exports)';
    }

    final selfPrefix = 'package:${package.name}/';
    if (uri.startsWith(selfPrefix)) {
      final rest = uri.substring(selfPrefix.length);

      if (rest.startsWith('src/')) {
        return 'Importing from src/ is forbidden; use top-level $layer.dart exports';
      }

      if (rest.startsWith('data/') || rest.startsWith('domain/') || rest.startsWith('presentation/')) {
        return 'Do not import from data/, domain/, or presentation/ directly; import the top-level barrel (data.dart/domain.dart/presentation.dart)';
      }
      const allowedBarrels = {'data.dart', 'domain.dart', 'presentation.dart'};
      final file = path.basename(rest);
      if (!allowedBarrels.contains(file)) {
        return 'Only top-level barrels data.dart, domain.dart, presentation.dart can be imported from within feature layers';
      }

      switch (layer) {
        case 'data':
          if (file == 'presentation.dart') {
            return 'data -> presentation dependency is not allowed';
          }
          return null;
        case 'domain':
          if (file == 'presentation.dart' || file == 'data.dart') {
            return 'domain must not depend on data or presentation';
          }
          return null;
        case 'presentation':
          if (file == 'data.dart') {
            return 'presentation -> data dependency is not allowed';
          }
          return null;
      }
    }

    if (uri.startsWith('package:')) {
      final externalPackage = _packageNameFromUri(uri);
      if (externalPackage != null && externalPackage != package.name) {
        final visibility = _validateExternalPackage(
          package,
          layer,
          externalPackage,
        );
        if (visibility != null) {
          return visibility;
        }
      }
    }

    return null;
  }

  String? _packageNameFromUri(String uri) {
    const prefix = 'package:';
    if (!uri.startsWith(prefix)) {
      return null;
    }
    final remainder = uri.substring(prefix.length);
    final slashIndex = remainder.indexOf('/');
    if (slashIndex == -1) {
      return remainder;
    }
    return remainder.substring(0, slashIndex);
  }

  String? _validateExternalPackage(
    _Package package,
    String layer,
    String externalPackage,
  ) {
    final rules = package.lintRules;
    if (rules == null || !rules.hasLayerRules) {
      return null;
    }
    final allowedPackages = rules.packagesForLayer(layer);
    if (allowedPackages == null || allowedPackages.isEmpty) {
      return null;
    }
    final normalizedPackage = externalPackage.toLowerCase();
    if (!allowedPackages.contains(normalizedPackage)) {
      final allowed = allowedPackages.toList()..sort();
      return 'Layer `$layer` only allows packages: ${allowed.join(', ')}';
    }
    return null;
  }
}

class _Package {
  _Package({
    required this.name,
    required this.dir,
  });

  final String name;
  final Directory dir;
  ModuleLintRules? lintRules;
}
