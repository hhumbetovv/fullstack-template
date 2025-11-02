import 'package:analyzer/dart/element/element2.dart';
import 'package:gen_core/base.dart';
import 'package:gen_core/extensions.dart';
import 'package:gen_core/utils.dart';
import 'package:processor/public.dart';
import 'package:source_gen/source_gen.dart';

class RootPaletteResolver extends BaseResolver<DataConfig, ClassElement2> {
  @override
  Future<DataConfig?> resolve(ClassElement2 element) async {
    final ConstructorElement2 constructor;

    try {
      constructor = element.constructors2.firstWhere((constructor) {
        return constructor.isFactory;
      });
    } on Object catch (_) {
      throw InvalidGenerationSourceError(
        'Class ${element.displayName} must have factory constructor',
        element: element,
      );
    }

    final params = constructor.formalParameters;

    return DataConfig(
      name: element.displayName,
      isFactory: true,
      fields: params.map((param) {
        throwIf(
          !param.isRequired,
          'Parameters of ${constructor.displayName} must be required ',
        );
        return FieldConfig(
          name: param.displayName,
          type: param.type.toString(),
          isNullable: param.type.isNullable,
          isRequired: param.isRequired,
          defaultValue: null,
        );
      }).toList(),
    );
  }
}
