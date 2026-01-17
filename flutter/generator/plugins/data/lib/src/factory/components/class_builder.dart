import 'package:code_builder/code_builder.dart';
import 'package:processor/public.dart';

class DataClassBuilder {
  DataClassBuilder({
    required this.writeSpec,
    required this.generateEquatable,
    required this.generateToString,
    required this.getAdditionalImplements,
    required this.getAdditionalMethods,
  });

  final void Function(Spec spec) writeSpec;
  final bool generateEquatable;
  final bool generateToString;
  final List<Reference> Function(DataConfig config) getAdditionalImplements;
  final List<Method> Function(DataConfig config) getAdditionalMethods;

  void writeClass(DataConfig config) {
    final isLoadableState = config.fields.any((element) {
      return element.name == 'isLoading';
    });
    final typeParams = _typeParameters(config);

    final dataClass = Class((classDef) {
      classDef
        ..annotations.add(refer('immutable'))
        ..types.addAll(typeParams)
        ..modifier = config.isFactory ? ClassModifier.base : null
        ..abstract = !config.isFactory
        ..name = '_${config.name}'
        ..implements.addAll([
          if (config.isFactory) _typeWithGenerics(config.name, config.generics),
          if (isLoadableState) refer('$LoadableState'),
          ...getAdditionalImplements(config),
        ])
        ..methods.addAll([
          if (isLoadableState) ...[
            Method((methodDef) {
              methodDef
                ..annotations.add(refer('override'))
                ..returns = _typeWithGenerics(config.name, config.generics)
                ..name = 'copyLoading'
                ..requiredParameters.add(
                  Parameter((paramDef) {
                    paramDef
                      ..type = refer('$bool')
                      ..name = 'isLoading';
                  }),
                )
                ..body = const Code('return applyIsLoading(isLoading);');
            }),
          ],
          ...getAdditionalMethods(config),
        ])
        ..constructors.add(
          Constructor((constDef) {
            constDef.constant = true;
            if (config.isFactory) {
              constDef.optionalParameters.addAll(
                config.fields.map((field) {
                  return Parameter((paramDef) {
                    paramDef
                      ..name = field.name
                      ..named = true
                      ..toThis = true
                      ..required = field.isRequired
                      ..defaultTo = field.defaultValue != null
                          ? Code(field.defaultValue!)
                          : null;
                  });
                }),
              );
            }
          }),
        )
        ..methods.addAll(
          [
            if (generateEquatable) ...[
              _equalOperator(config),
              _hashCodeMethod(config),
            ],
            if (generateToString) _toStringMethod(config),
          ],
        );

      if (config.isFactory) {
        classDef.fields.addAll(
          config.fields.map((field) {
            return Field((fieldDef) {
              fieldDef
                ..name = field.name
                ..modifier = FieldModifier.final$
                ..type = refer(field.type);
            });
          }),
        );
      }
    });

    writeSpec(dataClass);
  }

  Method _equalOperator(DataConfig config) {
    return Method((methodDef) {
      methodDef
        ..annotations.add(refer('override'))
        ..returns = refer('bool')
        ..name = 'operator =='
        ..requiredParameters.add(
          Parameter((paramDef) {
            paramDef
              ..name = 'other'
              ..type = refer('Object');
          }),
        )
        ..body = Code(
          'return identical(this, other) || other is _${config.name}${_genericsSuffix(config.generics)} ${config.fields.map((field) {
            return " && isEquals(other.${field.name}, ${field.name})";
          }).join(' ')};',
        );
    });
  }

  Method _hashCodeMethod(DataConfig config) {
    return Method((methodDef) {
      methodDef
        ..annotations.add(refer('override'))
        ..returns = refer('int')
        ..name = 'hashCode'
        ..type = MethodType.getter;
      if (config.fields.length > 19) {
        methodDef.body = Code(
          'return runtimeType.hashCode ^ ${config.fields.map((field) {
            return "${field.name}.hashCode";
          }).join(' ^ ')};',
        );
      } else {
        methodDef.body = Code(
          'return Object.hash(runtimeType, ${config.fields.map((field) {
            return field.name;
          }).join(',')});',
        );
      }
    });
  }

  Method _toStringMethod(DataConfig config) {
    return Method((methodDef) {
      methodDef
        ..annotations.add(refer('override'))
        ..returns = refer('$String')
        ..name = 'toString';

      final fields = config.fields
          .map((field) {
            return '${field.name}: \$${field.name}';
          })
          .join(', ');

      if (fields.isEmpty) {
        methodDef.body = Code("return '${config.name}';");
      } else {
        methodDef.body = Code("return '${config.name} { $fields }';");
      }
    });
  }
}

List<Reference> _typeParameters(DataConfig config) {
  return config.generics.map(refer).toList();
}

Reference _typeWithGenerics(String symbol, List<String> generics) {
  if (generics.isEmpty) return refer(symbol);
  return TypeReference((type) {
    type
      ..symbol = symbol
      ..types.addAll(generics.map(refer));
  });
}

String _genericsSuffix(List<String> generics) {
  if (generics.isEmpty) return '';
  return '<${generics.join(',')}>';
}
