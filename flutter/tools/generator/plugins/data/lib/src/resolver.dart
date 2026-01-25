import 'package:analyzer/dart/element/element2.dart';
import 'package:gen_core/base.dart';
import 'package:processor/public.dart';

import 'resolver/constructor_field_parser.dart';

class DataResolver extends BaseResolver<DataConfig, ClassElement2> {
  DataResolver({
    ConstructorFieldParser? fieldParser,
  }) : fieldParser = fieldParser ?? const ConstructorFieldParser();

  final ConstructorFieldParser fieldParser;

  @override
  Future<DataConfig?> resolve(ClassElement2 element) async {
    final constructor = element.constructors2[0];
    return DataConfig(
      name: element.displayName,
      isFactory: constructor.isFactory,
      generics: element.typeParameters2
          .map((parameter) => parameter.displayName)
          .toList(),
      fields: fieldParser.parseFields(constructor),
    );
  }
}
