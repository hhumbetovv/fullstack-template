import 'package:analyzer/dart/element/element2.dart';
import 'package:gen_core/base.dart';
import 'package:gen_core/utils.dart';
import 'package:gen_data/builder.dart';
import 'package:processor/public.dart';
import 'package:source_gen/source_gen.dart';

class RootPaletteResolver extends BaseResolver<DataConfig, ClassElement2> {
  RootPaletteResolver({
    ConstructorFieldParser? fieldParser,
  }) : fieldParser = fieldParser ?? const ConstructorFieldParser();

  final ConstructorFieldParser fieldParser;

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

    final fields = constructor.formalParameters.map((param) {
      throwIf(
        !param.isRequired,
        'Parameters of ${constructor.displayName} must be required ',
      );
      return fieldParser.parseField(
        parameter: param,
        isFactoryConstructor: true,
      );
    }).toList();

    return DataConfig(
      name: element.displayName,
      isFactory: true,
      fields: fields,
    );
  }
}
