// NO_DOC
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/element/element2.dart';
import 'package:gen_core/base.dart';
import 'package:gen_core/constants.dart';
import 'package:gen_core/extensions.dart';
import 'package:gen_core/utils.dart';
import 'package:processor/public.dart';
import 'package:source_gen/source_gen.dart';

class ViewModelResolver extends BaseResolver<ViewModelConfig, ClassElement2> {
  @override
  Future<ViewModelConfig?> resolve(ClassElement2 element) async {
    final baseName = element.displayName.trimBefore('ViewModel');

    final effects = getEffectConfigs(element.displayName);
    final intents = getIntentConfigs(
      element,
      effects.map((effect) => effect.method).toList(),
    );

    return ViewModelConfig(
      name: baseName,
      effects: getEffectConfigs(element.displayName),
      state: getStateConfig(element, baseName),
      intents: intents,
    );
  }

  StateConfig getStateConfig(ClassElement2 element, String baseName) {
    String? stateType;
    var isStatePrimitive = false;
    for (final field in element.fields2) {
      if (field.displayName == 'initialState' && field.type.toString() != Strings.unitType) {
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
        print('Error occurred: $e');
        return [];
      }
    }

    return effectConfigs;
  }

  List<MethodConfig> getIntentConfigs(
    ClassElement2 element,
    List<MethodConfig> effects,
  ) {
    final intents = <MethodConfig>[];
    try {
      for (final methodElement in element.methods2) {
        if (const TypeChecker.typeNamed(Intent).hasAnnotationOf(methodElement)) {
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
                return ParamConfig(name: param.displayName, type: param.type.toString());
              }).toList(),
            ),
          );
        }
      }
    } on Exception catch (e) {
      print('error occurred: $e');
      return [];
    }

    return intents;
  }
}
