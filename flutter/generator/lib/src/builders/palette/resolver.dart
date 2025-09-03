import 'package:analyzer/dart/element/element.dart';
import 'package:generator/src/base/base_resolver.dart';
import 'package:generator/src/extensions/dart_type.dart';
import 'package:generator/src/utils/throw.dart';
import 'package:processor/processor.dart';
import 'package:source_gen/source_gen.dart';

class PaletteResolver extends BaseResolver<DataConfig, ClassElement> {
  @override
  Future<DataConfig?> resolve(ClassElement element) async {
    final constructor = element.constructors[0];
    final params = constructor.parameters;
    final isFactory = constructor.isFactory;
    return DataConfig(
      name: element.name,
      isFactory: isFactory,
      fields: params.map((param) {
        final defaultValue = getDefault(param);
        if (constructor.isFactory) {
          throwIf(
            !param.type.isNullable && !param.isRequired && defaultValue == null,
            'Field ${param.name} must be marked as required or have a default value.',
          );

          throwIf(
            param.isRequired && defaultValue != null,
            "Field ${param.name} can't be marked as required and have a default value at the same time.",
          );
        }

        return FieldConfig(
          name: param.name,
          type: param.type.toString(),
          isNullable: param.type.isNullable,
          isRequired: param.isRequired,
          defaultValue: defaultValue,
        );
      }).toList(),
    );
  }

  String? getDefault(ParameterElement parameter) {
    const matcher = TypeChecker.fromRuntime(Default);
    for (final meta in parameter.metadata) {
      final obj = meta.computeConstantValue()!;
      if (matcher.isExactlyType(obj.type!)) {
        final source = meta.toSource();
        final res = source.substring('@Default('.length, source.length - 1);

        final needsConstModifier =
            !parameter.declaration.type.isDartCoreString &&
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
