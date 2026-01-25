import 'package:code_builder/code_builder.dart';
import 'package:gen_core/constants.dart';
import 'package:gen_core/extensions.dart';
import 'package:processor/public.dart';

class EffectMethodsBuilder {
  EffectMethodsBuilder({
    required this.suffix,
  });

  final String suffix;

  Iterable<Method> build(
    String baseName,
    Map<String, List<MethodConfig>> effectMap,
  ) {
    final viewName = '$baseName$suffix';
    return effectMap.entries.map((entry) {
      final MapEntry(key: viewModel, value: methods) = entry;
      final trimmed = viewModel.trimBefore(Strings.viewModelType);
      const effectParamName = 'effect';
      const contextParamName = 'context';

      final methodBody = methods.map((method) {
        final effectClass = '$trimmed${method.name.normalize().capitalize()}';
        final params = method.params
            .map((param) {
              if (param.type == Strings.contextType) return contextParamName;
              return '$effectParamName.${param.name}';
            })
            .join(',');

        return '$effectClass() => (this as $viewName).${method.name}($params),';
      }).join();

      return Method.returnsVoid((methodDef) {
        methodDef
          ..name = _getEffectMethodName(trimmed)
          ..requiredParameters.addAll([
            Parameter((paramDef) {
              paramDef
                ..name = contextParamName
                ..type = refer(Strings.contextType);
            }),
            Parameter((paramDef) {
              paramDef
                ..name = effectParamName
                ..type = refer('${trimmed}Effect');
            }),
          ])
          ..body = Code(
            'return switch(effect){'
            '$methodBody'
            '_ => null, '
            '};',
          );
      });
    });
  }

  String _getEffectMethodName(String name) {
    return '_on${name.capitalize()}EffectUpdate';
  }
}
