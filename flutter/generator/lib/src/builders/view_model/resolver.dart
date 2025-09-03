// NO_DOC
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:generator/src/base/base_resolver.dart';
import 'package:generator/src/constants/strings.dart';
import 'package:generator/src/extensions/dart_type.dart';
import 'package:generator/src/extensions/string.dart';
import 'package:generator/src/utils/throw.dart';
import 'package:processor/processor.dart';
import 'package:source_gen/source_gen.dart';

class ViewModelResolver extends BaseResolver<ViewModelConfig, ClassElement> {
  @override
  Future<ViewModelConfig?> resolve(ClassElement element) async {
    final baseName = element.name.trimBefore('ViewModel');

    final effects = getEffectConfigs(element.name);
    final intents = getIntentConfigs(
      element,
      effects.map((effect) => effect.method).toList(),
    );

    return ViewModelConfig(
      name: baseName,
      effects: getEffectConfigs(element.name),
      state: getStateConfig(element, baseName),
      intents: intents,
    );
  }

  StateConfig getStateConfig(ClassElement element, String baseName) {
    String? stateType;
    var isStatePrimitive = false;
    for (final field in element.fields) {
      if (field.name == 'initialState' && field.type.toString() != Strings.unitType) {
        stateType = field.type.toString();
        isStatePrimitive = field.type.isPrimitive;
      }
    }
    return StateConfig(typeName: stateType, isPrimitive: isStatePrimitive);
  }

  List<EffectConfig> getEffectConfigs(String className) {
    final cacheFile = File(Strings.effectsPath);
    final effectConfigs = <EffectConfig>[];
    if (cacheFile.existsSync()) {
      try {
        final cacheContent = List<Map<String, dynamic>>.from(
          jsonDecode(cacheFile.readAsStringSync()) as Iterable,
        );
        final cachedEffects = cacheContent.map((json) {
          return EffectConfig.fromJson(json);
        });
        for (final cachedEffect in cachedEffects) {
          final existedIndex = effectConfigs.indexWhere((effect) {
            return effect.method.name == cachedEffect.method.name;
          });

          if (existedIndex == -1) {
            if (cachedEffect.viewModel == className) {
              effectConfigs.add(cachedEffect);
            }
            continue;
          }
          final existedEffect = effectConfigs[existedIndex];
          throwIf(
            existedEffect != cachedEffect && existedEffect.viewModel == cachedEffect.viewModel,
            'There is an element with the same name but different configurations:\n'
            '\n${cachedEffect.method.name} in ${cachedEffect.view} and ${existedEffect.view}\n',
          );
        }
      } on Exception catch (e) {
        print('Error occured: $e');
        return [];
      }
    }

    return effectConfigs;
  }

  List<MethodConfig> getIntentConfigs(
    ClassElement element,
    List<MethodConfig> effects,
  ) {
    final intents = <MethodConfig>[];
    try {
      for (final methodElement in element.methods) {
        if (const TypeChecker.fromRuntime(Intent).hasAnnotationOf(methodElement)) {
          throwIf(
            effects.any((effect) {
              return effect.name.normalize() == methodElement.name.normalize();
            }),
            'there is an effect method with this name',
            element: methodElement,
          );

          intents.add(
            MethodConfig(
              name: methodElement.name,
              params: methodElement.parameters.map((param) {
                return ParamConfig(name: param.name, type: param.type.toString());
              }).toList(),
            ),
          );
        }
      }
    } on Exception catch (e) {
      print('error ocurred: $e');
      return [];
    }

    return intents;
  }
}
