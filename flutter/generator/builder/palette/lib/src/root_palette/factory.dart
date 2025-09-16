import 'package:code_builder/code_builder.dart';
import 'package:gen_palette/src/palette/factory.dart';
import 'package:processor/public.dart';

class RootPaletteFactory extends PaletteFactory {
  @override
  bool get generateApply => false;

  @override
  bool get generateToString => false;

  @override
  bool get generateEquatable => false;

  @override
  List<Method> getAdditionalMethods(DataConfig config) => [
    _createCopyWithMethod(config),
    _createLerpMethod(config),
    _createTypeGetter(config),
  ];

  Method _createCopyWithMethod(DataConfig config) {
    return Method((methodDef) {
      methodDef
        ..annotations.add(refer('override'))
        ..returns = refer('ThemeExtension<${config.name}>')
        ..name = 'copyWith'
        ..optionalParameters.addAll(
          config.fields.map((field) {
            return Parameter((paramDef) {
              paramDef
                ..name = field.name
                ..named = true
                ..type = refer('${field.type}?');
            });
          }),
        )
        ..body = Code(
          'return ${config.name}('
          '${config.fields.map((field) {
            return '${field.name}: ${field.name} ?? this.${field.name},';
          }).join('\n      ')}'
          ');',
        );
    });
  }

  Method _createLerpMethod(DataConfig config) {
    return Method((methodDef) {
      methodDef
        ..annotations.add(refer('override'))
        ..returns = refer('ThemeExtension<${config.name}>')
        ..name = 'lerp'
        ..requiredParameters.addAll([
          Parameter((paramDef) {
            paramDef
              ..name = 'other'
              ..type = refer('covariant ThemeExtension<${config.name}>?');
          }),
          Parameter((paramDef) {
            paramDef
              ..name = 't'
              ..type = refer('double');
          }),
        ])
        ..body = Code(_generateLerpBody(config));
    });
  }

  Method _createTypeGetter(DataConfig config) {
    return Method((methodDef) {
      methodDef
        ..annotations.add(refer('override'))
        ..returns = refer('Object')
        ..name = 'type'
        ..type = MethodType.getter
        ..lambda = true
        ..body = Code(config.name);
    });
  }

  String _generateLerpBody(DataConfig config) {
    return '''
    if (other is! ${config.name}) return this;

    return ${config.name}(
      ${getLerpParams(config.fields)}
    );''';
  }
}
