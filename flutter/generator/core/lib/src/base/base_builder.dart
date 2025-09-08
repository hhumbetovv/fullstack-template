// NO_DOC
// ignore_for_file: parameter_assignments

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:gen_core/src/utils/throw.dart';
import 'package:source_gen/source_gen.dart';

import 'base_factory.dart';
import 'base_resolver.dart';

const dartFormatWidth = '// dart format width=80';

abstract class BaseBuilder<Config, Target> extends Builder {
  BaseBuilder({
    required this.name,
    required this.buildFactory,
    required this.resolver,
    required this.annotation,
    List<String> additionalOutputExtensions = const [],
    this.allowSyntaxErrors = false,
    this.options,
  }) : generatedExtension = '.g.dart',
       buildExtensions = validatedBuildExtensionsFrom(options != null ? Map.of(options.config) : null, {
         '.dart': [
           '.g.dart',
           ...additionalOutputExtensions,
         ],
       }) {
    if (generatedExtension.isEmpty || !generatedExtension.startsWith('.')) {
      throw ArgumentError.value(
        generatedExtension,
        'generatedExtension',
        'Extension must be in the format of .*',
      );
    }

    if (options != null && additionalOutputExtensions.isNotEmpty) {
      throw ArgumentError(
        'Either `options` or `additionalOutputExtensions` parameter '
        'can be given. Not both.',
      );
    }
    _typeChecker = TypeChecker.typeNamed(annotation);
  }
  final String name;

  final Type annotation;
  late final TypeChecker _typeChecker;

  final String generatedExtension;

  final bool allowSyntaxErrors;

  final BaseFactory<Config> buildFactory;
  final BaseResolver<Config, Target> resolver;

  bool get cacheEnabled => options?.config['enable_cached_builds'] == true;

  String _defaultFormatOutput(String code) {
    code = '$dartFormatWidth\n$code';
    return DartFormatter(languageVersion: DartFormatter.latestLanguageVersion).format(code);
  }

  Set<String> get ignoreForFile => (options?.config['ignore_for_file'] as List?)?.cast<String>().toSet() ?? {};

  @override
  final Map<String, List<String>> buildExtensions;

  final BuilderOptions? options;

  @override
  Future<void> build(BuildStep buildStep) async {
    final resolver = buildStep.resolver;
    if (!await resolver.isLibrary(buildStep.inputId)) return;
    final unit = await resolver.compilationUnitFor(
      buildStep.inputId,
      allowSyntaxErrors: allowSyntaxErrors,
    );
    var cacheHash = 0;
    if (cacheEnabled) {
      cacheHash = calculateUpdatableHash(unit);
      final cached = loadFromCache(buildStep, cacheHash);
      if (cached != null) {
        return _writeContent(buildStep, cached);
      }
    }

    if (!(await hasAnyTopLevelAnnotations(buildStep.inputId, buildStep, unit))) {
      return;
    }

    final lib = await resolver.libraryFor(
      buildStep.inputId,
      allowSyntaxErrors: allowSyntaxErrors,
    );
    final generated = await onResolve(LibraryReader(lib), buildStep, cacheHash);
    saveToCache(buildStep, generated);
    if (generated == null) return;
    return _writeContent(buildStep, generated);
  }

  Map<String, dynamic>? toJson(Config? config);
  Config fromJson(Map<String, dynamic> json);

  File _cacheFile(int id) => File('.dart_tool/build/cache/${name}_$id.json');

  Config? loadFromCache(BuildStep buildStep, int stepHash) {
    final file = _cacheFile(buildStep.inputId.path.hashCode);
    if (file.existsSync()) {
      final json = jsonDecode(file.readAsStringSync());
      final cachedConfig = fromJson(json as Map<String, dynamic>);
      if (cachedConfig.hashCode == stepHash) {
        return cachedConfig;
      }
    }
    return null;
  }

  void saveToCache(BuildStep buildStep, Config? config) {
    final cacheFile = _cacheFile(buildStep.inputId.path.hashCode);

    if (!cacheFile.existsSync()) {
      cacheFile.createSync(recursive: true);
    }

    final jsonOutput = jsonEncode(toJson(config));
    cacheFile.writeAsStringSync(jsonOutput);
  }

  int calculateUpdatableHash(CompilationUnit unit);

  Future<String> onGenerateContent(BuildStep buildStep, Config item) async {
    return buildFactory.stringify(item);
  }

  Future<Config?> onResolve(LibraryReader library, BuildStep buildStep, int stepHash) async {
    final elements = library.annotatedWith(_typeChecker);

    if (elements.isEmpty) return null;

    final annotatedElement = elements.first.element;

    throwIf(
      annotatedElement is! Target,
      '${annotatedElement.displayName} is not a $Target',
    );

    final element = annotatedElement as Target;

    return resolver.resolve(element);
  }

  String validateAndFormatDartCode(BuildStep buildStep, String generated) {
    try {
      return _defaultFormatOutput(generated);
    } on Exception catch (e, stack) {
      log.severe(
        '''
An error `${e.runtimeType}` occurred while formatting the generated source for
  `${buildStep.inputId.path}`
which was output to
  `${buildStep.allowedOutputs.first.path}`.
This may indicate an issue in the generator, the input source code, or in the
source formatter.''',
        e,
        stack,
      );
      return generated;
    }
  }

  Future<void> _writeContent(BuildStep buildStep, Config generated) async {
    var output = await onGenerateContent(buildStep, generated);
    output =
        '''
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// $annotation Generator
// **************************************************************************

part of '${buildStep.inputId.pathSegments.last}';


$output
''';

    final partFile = File('${buildStep.inputId.path.split('.').first}.g.dart');
    if (!partFile.existsSync()) {
      await partFile.create(recursive: true);
    }
    await partFile.writeAsString(output);

    final outputId = buildStep.allowedOutputs.first;
    if (outputId.extension.endsWith('.dart')) {
      output = validateAndFormatDartCode(buildStep, output);
    }
    return buildStep.writeAsString(outputId, output);
  }

  @override
  String toString() => 'Generating $generatedExtension: $runtimeType';

  Future<bool> hasAnyTopLevelAnnotations(AssetId input, BuildStep buildStep, [CompilationUnit? unit]) async {
    if (!await buildStep.canRead(input)) return false;
    final lib = await buildStep.resolver.libraryFor(input);
    final reader = LibraryReader(lib);

    if (reader.annotatedWith(_typeChecker).isNotEmpty) {
      return true;
    }

    final parsed = unit ?? await buildStep.resolver.compilationUnitFor(input);
    final partIds = <AssetId>[];
    for (final directive in parsed.directives) {
      if (directive is PartDirective) {
        partIds.add(
          AssetId.resolve(Uri.parse(directive.uri.stringValue!), from: input),
        );
      }
    }
    for (final partId in partIds) {
      if (await hasAnyTopLevelAnnotations(partId, buildStep)) {
        return true;
      }
    }
    return false;
  }
}

Map<String, List<String>> validatedBuildExtensionsFrom(
  Map<String, dynamic>? optionsMap,
  Map<String, List<String>> defaultExtensions,
) {
  final extensionsOption = optionsMap?.remove('build_extensions');
  if (extensionsOption == null) return defaultExtensions;

  throw ArgumentError(
    'Configured build_extensions should be a map from inputs to outputs.',
  );
}
