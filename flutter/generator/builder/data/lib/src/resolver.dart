import 'package:analyzer/dart/element/element2.dart';
import 'package:gen_core/base.dart';
import 'package:gen_core/extensions.dart';
import 'package:gen_core/utils.dart';
import 'package:processor/public.dart';
import 'package:source_gen/source_gen.dart';

class DataResolver extends BaseResolver<DataConfig, ClassElement2> {
  @override
  Future<DataConfig?> resolve(ClassElement2 element) async {
    final constructor = element.constructors2[0];
    final params = constructor.formalParameters;
    final isFactory = constructor.isFactory;
    return DataConfig(
      name: element.displayName,
      isFactory: isFactory,
      fields: params.map((param) {
        final defaultValue = getDefault(param);
        if (constructor.isFactory) {
          throwIf(
            !param.type.isNullable && !param.isRequired && defaultValue == null,
            'Field ${param.displayName} must be marked as required or have a default value.',
          );

          throwIf(
            param.isRequired && defaultValue != null,
            "Field ${param.displayName} can't be marked as required and have a default value at the same time.",
          );
        }

        return FieldConfig(
          name: param.displayName,
          type: param.type.toString(),
          isNullable: param.type.isNullable,
          isRequired: param.isRequired,
          defaultValue: defaultValue,
        );
      }).toList(),
    );
  }

  String? getDefault(FormalParameterElement parameter) {
    const matcher = TypeChecker.typeNamed(Default);
    for (final meta in parameter.metadata2.annotations) {
      final obj = meta.computeConstantValue()!;
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
