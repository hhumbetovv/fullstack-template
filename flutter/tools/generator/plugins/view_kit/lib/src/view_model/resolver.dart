// ignore_for_file: avoid_print

import 'package:analyzer/dart/element/element.dart';
import 'package:gen_core/base.dart';
import 'package:gen_core/constants.dart';
import 'package:gen_core/extensions.dart';
import 'package:gen_core/utils.dart';
import 'package:gen_view_kit/src/shared/effect_cache_adapter.dart';
import 'package:processor/public.dart';
import 'package:source_gen/source_gen.dart';
import 'package:tools_common/tooling.dart';

class ViewModelResolver extends BaseResolver<ViewModelConfig, ClassElement> {
  ViewModelResolver({
    EffectCache? effectCache,
    this.effectCacheAdapter = const EffectCacheAdapter(),
  }) : effectCache = effectCache ?? EffectCache();

  final EffectCache effectCache;
  final EffectCacheAdapter effectCacheAdapter;

  @override
  Future<ViewModelConfig?> resolve(ClassElement element) async {
    final baseName = element.displayName.trimBefore('ViewModel');

    final effects = getEffectConfigs(element.displayName);
    final intents = getIntentConfigs(
      element,
      effects.map((effect) => effect.method).toList(),
    );

    return ViewModelConfig(
      name: baseName,
      effects: effects,
      state: getStateConfig(element, baseName),
      intents: intents,
    );
  }

  StateConfig getStateConfig(ClassElement element, String baseName) {
    String? stateType;
    var isStatePrimitive = false;
    for (final field in element.fields) {
      if (field.displayName == 'initialState' && field.type.toString() != Strings.unitType) {
        stateType = field.type.toString();
        isStatePrimitive = field.type.isPrimitive;
      }
    }
    return StateConfig(typeName: stateType, isPrimitive: isStatePrimitive);
  }

  List<EffectConfig> getEffectConfigs(String className) {
    try {
      final cached = effectCache.readForViewModel(className);
      return effectCacheAdapter.fromCachedEffects(cached);
    } on Object catch (e) {
      print('Error occurred: $e');
      return [];
    }
  }

  List<MethodConfig> getIntentConfigs(
    ClassElement element,
    List<MethodConfig> effects,
  ) {
    final intents = <MethodConfig>[];
    try {
      for (final methodElement in element.methods) {
        if (const TypeChecker.typeNamed(
          Intent,
        ).hasAnnotationOf(methodElement)) {
          throwIf(
            effects.any((effect) {
              return effect.name.normalize() == methodElement.displayName.normalize();
            }),
            'there is an effect method with this name',
            element: methodElement,
          );

          intents.add(
            MethodConfig(
              name: methodElement.displayName,
              params: methodElement.formalParameters.map((param) {
                return ParamConfig(
                  name: param.displayName,
                  type: param.type.toString(),
                );
              }).toList(),
            ),
          );
        }
      }
    } on Object catch (e) {
      print('error occurred: $e');
      return [];
    }

    return intents;
  }
}
