import 'dart:convert';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:common_tooling/tooling.dart';
import 'package:gen_core/extensions.dart';
import 'package:gen_view_kit/src/shared/effect_cache_adapter.dart';
import 'package:processor/public.dart';
import 'package:source_gen/source_gen.dart';

class ViewEffectBuilder implements Builder {
  ViewEffectBuilder({BuilderOptions? options})
    : buildExtensions = const {
        '.dart': ['.view_effect.json'],
      } {
    final _ = options;
  }

  final EffectCache _effectCache = EffectCache();
  final EffectCacheAdapter _effectCacheAdapter = const EffectCacheAdapter();
  static const _effectName = 'Effect';
  static const _viewName = 'View';
  static const _providerName = 'Provider';

  @override
  final Map<String, List<String>> buildExtensions;

  @override
  Future<void> build(BuildStep buildStep) async {
    if (!await buildStep.resolver.isLibrary(buildStep.inputId)) return;

    final library = await buildStep.resolver.libraryFor(
      buildStep.inputId,
      allowSyntaxErrors: true,
    );
    final reader = LibraryReader(library);

    final cachedViews = _effectCache.readAll().map((effect) => effect.view).toSet();
    final viewEffects = <String, List<EffectConfig>>{};

    for (final clazz in reader.classes.whereType<ClassElement2>()) {
      final effects = _resolveEffects(clazz);
      final hasDefaultOwner = _hasOwnerAnnotation(clazz);
      final shouldUpdate = effects.isNotEmpty || hasDefaultOwner || cachedViews.contains(clazz.displayName);
      if (!shouldUpdate) continue;
      viewEffects[clazz.displayName] = effects;
    }

    for (final entry in viewEffects.entries) {
      _effectCache.upsertViewEffects(
        viewClassName: entry.key,
        effects: _effectCacheAdapter.toCachedEffects(entry.value),
      );
    }

    final baseOutput = buildStep.inputId.changeExtension('.view_effect.json');
    final basePayload = viewEffects.values
        .expand((value) => value)
        .map((effect) => effect.toJson())
        .toList();
    await buildStep.writeAsString(baseOutput, jsonEncode(basePayload));
  }

  List<EffectConfig> _resolveEffects(ClassElement2 element) {
    final effects = <EffectConfig>[];

    for (final method in element.methods2) {
      final annotation = _effectAnnotation(method);
      if (annotation == null) continue;

      final viewModels = _resolveViewModels(element, annotation, method);
      for (final viewModel in viewModels) {
        effects.add(
          EffectConfig(
            view: element.displayName,
            viewModel: viewModel,
            method: MethodConfig(
              name: method.displayName,
              params: method.formalParameters.map<ParamConfig>((param) {
                return ParamConfig(
                  name: param.displayName,
                  type: param.type.toString(),
                );
              }).toList(),
            ),
          ),
        );
      }
    }

    return effects;
  }

  List<String> _resolveViewModels(
    ClassElement2 element,
    DartObject annotation,
    MethodElement2 method,
  ) {
    final from = annotation.getField('from')?.toListValue() ?? const [];
    final viewModels = from
        .map((typeValue) => typeValue.toTypeValue()?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toList();

    if (viewModels.isNotEmpty) {
      return viewModels;
    }

    final defaultViewModel = _defaultViewModel(element);
    if (defaultViewModel == null) {
      throw InvalidGenerationSourceError(
        '@effect used outside @view/@provider must declare @Effect(from: [...]).',
        element: method,
      );
    }
    return [defaultViewModel];
  }

  bool _hasOwnerAnnotation(ClassElement2 element) {
    return _hasAnnotation(element, _viewName) || _hasAnnotation(element, _providerName);
  }

  String? _defaultViewModel(ClassElement2 element) {
    if (_hasAnnotation(element, _viewName)) {
      return '${element.displayName.trimBefore('View')}ViewModel';
    }
    if (_hasAnnotation(element, _providerName)) {
      return '${element.displayName.trimBefore('Provider')}ViewModel';
    }
    return null;
  }

  DartObject? _effectAnnotation(MethodElement2 method) {
    for (final annotation in method.metadata2.annotations) {
      final constantValue = annotation.computeConstantValue();
      if (constantValue?.type?.getDisplayString() == _effectName) {
        return constantValue;
      }
    }
    return null;
  }

  bool _hasAnnotation(ClassElement2 element, String name) {
    for (final annotation in element.metadata2.annotations) {
      final constantValue = annotation.computeConstantValue();
      if (constantValue?.type?.getDisplayString() == name) {
        return true;
      }
    }
    return false;
  }

}
