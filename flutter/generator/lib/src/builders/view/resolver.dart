import 'package:analyzer/dart/element/element2.dart';
import 'package:generator/src/base/base_resolver.dart';
import 'package:generator/src/extensions/string.dart';
import 'package:processor/processor.dart';

class ViewResolver extends BaseResolver<ViewConfig, ClassElement2> {
  String get suffix => 'view';

  @override
  Future<ViewConfig?> resolve(ClassElement2 element) async {
    final baseName = element.displayName.trimBefore(suffix);

    final effects = getEffectConfigs(
      element.displayName,
      baseName,
      element.methods2,
    );

    final isStateful = checkIsStateful(element.methods2);

    return ViewConfig(
      name: baseName,
      effects: effects,
      isStateful: isStateful,
      customFactory: hasCustomFactory(element.methods2),
    );
  }

  List<EffectConfig> getEffectConfigs(String className, String baseName, List<MethodElement2> methods) {
    final effects = <EffectConfig>[];

    for (final method in methods) {
      annotationLoop:
      for (final annotation in method.metadata2.annotations) {
        final constantValue = annotation.computeConstantValue();
        if (constantValue?.type?.getDisplayString() == 'Effect') {
          final viewModels = (constantValue?.getField('from')?.toListValue() ?? [])
              .map((typeValue) => typeValue.toTypeValue()?.toString() ?? '')
              .where((value) => value.isNotEmpty)
              .toList();

          if (viewModels.isEmpty) {
            viewModels.add('${baseName}ViewModel');
          }

          for (final viewModel in viewModels) {
            effects.add(
              EffectConfig(
                view: className,
                viewModel: viewModel,
                method: MethodConfig(
                  name: method.displayName,
                  params: method.formalParameters.map((param) {
                    return ParamConfig(name: param.displayName, type: param.type.toString());
                  }).toList(),
                ),
              ),
            );
          }
          break annotationLoop;
        }
      }
    }
    return effects;
  }

  bool checkIsStateful(List<MethodElement2> methods) {
    return methods.any((method) {
      if (method.displayName == 'initState' || method.displayName == 'dispose') {
        return method.metadata2.annotations.any((annotation) {
          return annotation.isOverride;
        });
      }

      return false;
    });
  }

  bool hasCustomFactory(List<MethodElement2> methods) {
    return methods.any((method) {
      if (method.displayName == 'viewModelFactory' && method.metadata2.annotations.any((ann) => ann.isOverride)) {
        return true;
      }

      return false;
    });
  }
}
