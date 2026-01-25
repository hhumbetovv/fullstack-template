import 'package:analyzer/dart/element/element2.dart';
import 'package:gen_core/extensions.dart';
import 'package:gen_core/utils.dart';
import 'package:processor/public.dart';
import 'package:source_gen/source_gen.dart';

class ConstructorFieldParser {
  const ConstructorFieldParser();

  List<FieldConfig> parseFields(ConstructorElement2 constructor) {
    return constructor.formalParameters
        .map(
          (param) => parseField(
            parameter: param,
            isFactoryConstructor: constructor.isFactory,
          ),
        )
        .toList();
  }

  FieldConfig parseField({
    required FormalParameterElement parameter,
    required bool isFactoryConstructor,
  }) {
    final defaultValue = _getDefault(parameter);
    if (isFactoryConstructor) {
      throwIf(
        !parameter.type.isNullable &&
            !parameter.isRequired &&
            defaultValue == null,
        'Field ${parameter.displayName} must be marked as required or have a default value.',
      );

      throwIf(
        parameter.isRequired && defaultValue != null,
        "Field ${parameter.displayName} can't be marked as required and have a default value at the same time.",
      );
    }

    return FieldConfig(
      name: parameter.displayName,
      type: parameter.type.toString(),
      isNullable: parameter.type.isNullable,
      isRequired: parameter.isRequired,
      defaultValue: defaultValue,
    );
  }

  String? _getDefault(FormalParameterElement parameter) {
    const matcher = TypeChecker.typeNamed(Default);
    for (final meta in parameter.metadata2.annotations) {
      final obj = meta.computeConstantValue();
      if (obj == null) continue;
      if (matcher.isExactlyType(obj.type!)) {
        final source = meta.toSource();
        final res = source.substring('@Default('.length, source.length - 1);

        final needsConstModifier =
            !parameter.type.isDartCoreString &&
            !res.trimLeft().startsWith('const') &&
            (res.contains('(') || res.contains('[') || res.contains('{'));

        if (needsConstModifier) {
          return 'const $res';
        } else {
          return res;
        }
      }
    }
    return null;
  }
}
