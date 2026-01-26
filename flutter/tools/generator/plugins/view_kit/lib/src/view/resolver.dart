import 'package:analyzer/dart/element/element.dart';
import 'package:gen_core/base.dart';
import 'package:gen_core/extensions.dart';
import 'package:processor/public.dart';

class ViewResolver extends BaseResolver<ViewConfig, ClassElement> {
  String get suffix => 'view';

  @override
  Future<ViewConfig?> resolve(ClassElement element) async {
    final baseName = element.displayName.trimBefore(suffix);

    final effects = getEffectConfigs(
      element.displayName,
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
      for (final annotation in method.metadata.annotations) {
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

  bool checkIsStateful(List<MethodElement> methods) {
    return methods.any((method) {
      if (method.displayName == 'initState' || method.displayName == 'dispose') {
        return method.metadata.annotations.any((annotation) {
          return annotation.isOverride;
        });
      }

      return false;
    });
  }

  bool hasCustomFactory(List<MethodElement> methods) {
    return methods.any((method) {
      if (method.displayName == 'viewModelFactory' && method.metadata.annotations.any((ann) => ann.isOverride)) {
        return true;
      }

      return false;
    });
  }
}
