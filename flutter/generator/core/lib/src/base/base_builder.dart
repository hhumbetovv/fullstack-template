// NO_DOC
// ignore_for_file: parameter_assignments

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:gen_core/src/services/annotation_scanner.dart';
import 'package:gen_core/src/services/cache_service.dart';
import 'package:gen_core/src/services/generator_context.dart';
import 'package:gen_core/src/services/output_service.dart';
import 'package:gen_core/src/utils/throw.dart';
import 'package:source_gen/source_gen.dart';

import 'base_factory.dart';
import 'base_resolver.dart';

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
       buildExtensions = validatedBuildExtensionsFrom(
         options != null ? Map.of(options.config) : null,
         {
           '.dart': [
             '.g.dart',
             ...additionalOutputExtensions,
           ],
         },
       ) {
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
    _annotationScanner = AnnotationScanner(_typeChecker);
    _cacheService = BuildCacheService<Config>(
      builderName: name,
      toJson: toJson,
      fromJson: fromJson,
    );
    _outputService = GeneratedOutputService();
  }
  final String name;

  final Type annotation;
  late final TypeChecker _typeChecker;
  late final AnnotationScanner _annotationScanner;
  late final BuildCacheService<Config> _cacheService;
  late final GeneratedOutputService _outputService;

  final String generatedExtension;

  final bool allowSyntaxErrors;

  final BaseFactory<Config> buildFactory;
  final BaseResolver<Config, Target> resolver;

  bool get cacheEnabled => options?.config['enable_cached_builds'] == true;

  Set<String> get ignoreForFile =>
      (options?.config['ignore_for_file'] as List?)?.cast<String>().toSet() ??
      {};

  @override
  final Map<String, List<String>> buildExtensions;

  final BuilderOptions? options;

  @override
  Future<void> build(BuildStep buildStep) async {
    final resolver = buildStep.resolver;
    final context = GeneratorContext(buildStep: buildStep);
    if (!await resolver.isLibrary(buildStep.inputId)) return;
    final unit = await resolver.compilationUnitFor(
      buildStep.inputId,
      allowSyntaxErrors: allowSyntaxErrors,
    );
    var cacheHash = 0;
    if (cacheEnabled) {
      cacheHash = calculateUpdatableHash(unit);
      final cached = _cacheService.read(buildStep.inputId, cacheHash);
      if (cached != null) {
        return _writeGeneratedOutput(context, cached);
      }
    }

    final hasAnnotations = await _annotationScanner.hasAnyTopLevelAnnotations(
      buildStep,
      buildStep.inputId,
      compilationUnit: unit,
      allowSyntaxErrors: allowSyntaxErrors,
    );

    if (!hasAnnotations) {
      return;
    }

    final lib = await resolver.libraryFor(
      buildStep.inputId,
      allowSyntaxErrors: allowSyntaxErrors,
    );
    final generated = await onResolve(LibraryReader(lib), buildStep, cacheHash);
    _cacheService.write(buildStep.inputId, generated);
    if (generated == null) return;
    return _writeGeneratedOutput(context, generated);
  }

  Map<String, dynamic>? toJson(Config? config);
  Config fromJson(Map<String, dynamic> json);

  int calculateUpdatableHash(CompilationUnit unit);

  Future<String> onGenerateContent(BuildStep buildStep, Config item) async {
    return buildFactory.stringify(item);
  }

  Future<Config?> onResolve(
    LibraryReader library,
    BuildStep buildStep,
    int stepHash,
  ) async {
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

  Future<void> _writeGeneratedOutput(
    GeneratorContext context,
    Config generated,
  ) async {
    final content = await onGenerateContent(context.buildStep, generated);
    await _outputService.write(
      context: context,
      annotationName: '$annotation',
      content: content,
    );
  }

  @override
  String toString() => 'Generating $generatedExtension: $runtimeType';
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
