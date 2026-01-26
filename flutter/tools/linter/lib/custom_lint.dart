import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:feature_layer_linter/src/module_config.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

PluginBase createPlugin() => _FeatureLintPlugin();

class _FeatureLintPlugin extends PluginBase {
  _FeatureLintPlugin();

  @override
  List<LintRule> getLintRules(CustomLintConfigs _) => <LintRule>[
    const _FeatureImportsRule(),
  ];
}

class _FeatureImportsRule extends DartLintRule {
  const _FeatureImportsRule() : super(code: _code);

  static const _code = LintCode(
    name: 'feature_imports',
    problemMessage: 'Import violates feature module rules',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addImportDirective((ImportDirective directive) {
      final sourcePath = resolver.source.fullName;

      final packageDir = _findPackageRoot(Directory(path.dirname(sourcePath)));
      if (packageDir == null) return;
      final packageName = _readPackageName(packageDir);
      if (packageName == null) return;

      final relative = path.normalize(path.relative(sourcePath, from: packageDir.path));
      final layer = _layerFor(relative);
      if (layer == null) return;

      final rules = loadModuleLintRules(
        workspaceRoot: _findWorkspaceRoot(packageDir),
        moduleDirectory: packageDir,
      );
      final uri = directive.uri.stringValue;
      if (uri == null) return;
      final message = _validateImport(
        packageName: packageName,
        layer: layer,
        uri: uri,
        rules: rules,
      );
      if (message != null) {
        reporter.atNode(
          directive.uri,
          LintCode(
            name: 'feature_imports',
            problemMessage: message,
          ),
        );
      }
    });
  }

  String? _validateImport({
    required String packageName,
    required String layer,
    required String uri,
    required ModuleLintRules? rules,
  }) {
    if (uri.startsWith('./') || uri.startsWith('../')) {
      return 'Relative imports are not allowed under lib/src/$layer (use package:$packageName/$layer.dart exports)';
    }

    final selfPrefix = 'package:$packageName/';
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
          if (file == 'presentation.dart') return 'data -> presentation dependency is not allowed';
        case 'domain':
          if (file == 'presentation.dart' || file == 'data.dart') {
            return 'domain must not depend on data or presentation';
          }
        case 'presentation':
          if (file == 'data.dart') return 'presentation -> data dependency is not allowed';
      }
    }

    if (uri.startsWith('package:')) {
      final pkg = _packageNameFromUri(uri);
      if (pkg != null && pkg != packageName) {
        final allowed = rules?.packagesForLayer(layer);
        if (allowed != null && allowed.isNotEmpty && !allowed.contains(pkg.toLowerCase())) {
          final list = (allowed.toList()..sort()).join(', ');
          return 'Layer `$layer` only allows packages: $list';
        }
      }
    }
    return null;
  }

  String? _layerFor(String relativePath) {
    final normalized = relativePath.replaceAll(r'\', '/');
    if (normalized.startsWith('lib/src/data/')) return 'data';
    if (normalized.startsWith('lib/src/domain/')) return 'domain';
    if (normalized.startsWith('lib/src/presentation/')) return 'presentation';
    return null;
  }

  String? _packageNameFromUri(String uri) {
    const prefix = 'package:';
    if (!uri.startsWith(prefix)) return null;
    final rem = uri.substring(prefix.length);
    final slash = rem.indexOf('/');
    return slash == -1 ? rem : rem.substring(0, slash);
  }

  Directory _findWorkspaceRoot(Directory start) {
    var dir = start.absolute;
    while (true) {
      final pubspec = File(path.join(dir.path, 'pubspec.yaml'));
      if (pubspec.existsSync()) {
        final content = pubspec.readAsStringSync();
        if (content.contains('\nworkspace:') || content.trimLeft().startsWith('workspace:')) {
          return dir;
        }
      }
      final parent = dir.parent;
      if (parent.path == dir.path) return start;
      dir = parent;
    }
  }

  Directory? _findPackageRoot(Directory start) {
    var dir = start.absolute;
    while (true) {
      final pubspec = File(path.join(dir.path, 'pubspec.yaml'));
      if (pubspec.existsSync()) return dir;
      final parent = dir.parent;
      if (parent.path == dir.path) return null;
      dir = parent;
    }
  }

  String? _readPackageName(Directory packageDir) {
    final file = File(path.join(packageDir.path, 'pubspec.yaml'));
    if (!file.existsSync()) return null;
    final content = file.readAsStringSync();
    final yaml = loadYaml(content);
    return yaml is YamlMap ? yaml['name']?.toString() : null;
  }
}
