import 'package:analyzer/dart/element/element.dart';
import 'package:generator/src/base/base_resolver.dart';
import 'package:generator/src/extensions/string.dart';
import 'package:processor/processor.dart';

class ViewResolver extends BaseResolver<ViewConfig, ClassElement> {
  String get suffix => 'view';

  @override
  Future<ViewConfig?> resolve(ClassElement element) async {
    final baseName = element.name.trimBefore(suffix);

    final effects = getEffectConfigs(
      element.name,
      baseName,
      element.methods,
    );

    final isStateful = checkIsStateful(element.methods);

    return ViewConfig(
      name: baseName,
      effects: effects,
      isStateful: isStateful,
      customFactory: hasCustomFactory(element.methods),
    );
  }

  List<EffectConfig> getEffectConfigs(String className, String baseName, List<MethodElement> methods) {
    final effects = <EffectConfig>[];

    for (final method in methods) {
      annotationLoop:
      for (final annotation in method.metadata) {
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
                  name: method.name,
                  params: method.parameters.map((param) {
                    return ParamConfig(name: param.name, type: param.type.toString());
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

  bool checkIsStateful(List<MethodElement> methods) {
    return methods.any((method) {
      if (method.name == 'initState' || method.name == 'dispose') {
        return method.metadata.any((annotation) {
          return annotation.isOverride;
        });
      }

      return false;
    });
  }

  bool hasCustomFactory(List<MethodElement> methods) {
    return methods.any((method) {
      if (method.name == 'viewModelFactory' && method.metadata.any((ann) => ann.isOverride)) {
        return true;
      }

      return false;
    });
  }
}
