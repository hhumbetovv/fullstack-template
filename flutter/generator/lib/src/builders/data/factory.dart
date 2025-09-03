import 'package:code_builder/code_builder.dart';
import 'package:generator/src/base/base_factory.dart';
import 'package:generator/src/extensions/string.dart';
import 'package:processor/processor.dart';

class DataFactory extends BaseFactory<DataConfig> {
  bool get generateCopy => true;
  bool get generateToString => true;
  bool get generateApply => true;
  bool get generateEquatable => true;

  @override
  void build(DataConfig config) {
    createClass(config);

    createGetters(config);

    if (generateCopy) createCopy(config);

    if (generateApply) createApply(config);
  }

  void createClass(DataConfig config) {
    final isLoadableState = config.fields.any((element) {
      return element.name == 'isLoading';
    });
    final dataClass = Class((classDef) {
      classDef
        ..annotations.add(refer('immutable'))
        ..modifier = config.isFactory ? ClassModifier.base : null
        ..abstract = !config.isFactory
        ..name = '_${config.name}'
        ..implements.addAll([
          if (config.isFactory) refer(config.name),
          if (isLoadableState) refer('$LoadableState'),
        ])
        ..methods.addAll([
          if (isLoadableState) ...[
            Method((methodDef) {
              methodDef
                ..annotations.add(refer('override'))
                ..returns = refer(config.name)
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
                      ..defaultTo = field.defaultValue != null ? Code(field.defaultValue!) : null;
                  });
                }),
              );
            }
          }),
        )
        ..methods.addAll(
          [
            if (generateEquatable) ...[
              equalOperator(config),
              hashCodeMethod(config),
            ],
            if (generateToString) toStringMethod(config),
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

  Method equalOperator(DataConfig config) {
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
          'return identical(this, other) || other is _${config.name} ${config.fields.map((field) {
            return " && isEquals(other.${field.name}, ${field.name})";
          }).join(' ')};',
        );
    });
  }

  Method hashCodeMethod(DataConfig config) {
    return Method((methodDef) {
      methodDef
        ..annotations.add(refer('override'))
        ..returns = refer('int')
        ..name = 'hashCode'
        ..type = MethodType.getter;
      if (config.fields.length > 19) {
        methodDef.body = Code('return runtimeType.hashCode ^ ${config.fields.map((field) {
          return "${field.name}.hashCode";
        }).join(' ^ ')};');
      } else {
        methodDef.body = Code('return Object.hash(runtimeType, ${config.fields.map((field) {
          return field.name;
        }).join(',')});');
      }
    });
  }

  Method toStringMethod(DataConfig config) {
    return Method((methodDef) {
      methodDef
        ..annotations.add(refer('override'))
        ..returns = refer('$String')
        ..name = 'toString';

      final fields = config.fields.map((field) {
        return '${field.name}: \$${field.name}';
      }).join(', ');

      if (fields.isEmpty) {
        methodDef.body = Code("return '${config.name}';");
      } else {
        methodDef.body = Code("return '${config.name} { $fields }';");
      }
    });
  }

  void createGetters(DataConfig config) {
    final ref = config.isFactory ? '_self' : '(this as ${config.name})';
    final getterExtension = Extension((extDef) {
      extDef
        ..name = '${!config.isFactory ? '_' : ''}${config.name}Getter'
        ..on = refer('${!config.isFactory ? '_' : ''}${config.name}')
        ..methods.addAll(
          [
            if (config.isFactory)
              Method((methodDef) {
                methodDef
                  ..returns = refer('_${config.name}')
                  ..type = MethodType.getter
                  ..name = '_self'
                  ..lambda = true
                  ..body = Code('this as _${config.name}');
              }),
            ...config.fields.map((field) {
              return Method((methodDef) {
                methodDef
                  ..returns = refer(field.type)
                  ..type = MethodType.getter
                  ..name = field.name
                  ..lambda = true
                  ..body = Code('$ref.${field.name}');
              });
            }),
          ],
        );
    });

    writeSpec(getterExtension);
  }

  void createCopy(DataConfig config) {
    final ref = config.isFactory ? '_self' : 'this';
    final copyExt = Extension((extDef) {
      extDef
        ..name = '${config.name}Copy'
        ..on = refer(config.name)
        ..methods.add(
          Method((methodDef) {
            methodDef
              ..returns = refer(config.name)
              ..name = 'copy'
              ..optionalParameters.addAll(
                config.fields.map((field) {
                  return Parameter((paramDef) {
                    paramDef
                      ..name = field.name
                      ..named = true
                      ..type = refer(
                        '${field.type} ${field.isNullable ? 'Function()' : ''}?',
                      );
                  });
                }),
              )
              ..body = Code('return ${config.isFactory ? '_' : ''}${config.name}('
                  '${config.fields.map((field) {
                final name = field.name;
                if (field.isNullable) {
                  return '$name: $name != null ? $name() : $ref.$name,';
                }
                return '$name: $name ?? $ref.$name,';
              }).join(' ')}'
                  ');');
          }),
        );
    });

    writeSpec(copyExt);
  }

  void createApply(DataConfig config) {
    final applyExt = Extension((extDef) {
      extDef
        ..name = '${config.name}Apply'
        ..on = refer(config.name)
        ..methods.addAll(
          config.fields.map((field) {
            return Method((methodDef) {
              methodDef
                ..returns = refer(config.name)
                ..name = 'apply${field.name.capitalize()}'
                ..requiredParameters.add(
                  Parameter((paramDef) {
                    paramDef
                      ..type = refer(field.type)
                      ..name = field.name;
                  }),
                )
                ..lambda = true
                ..body = Code(
                  'copy(${field.name}: ${field.isNullable ? '() => ' : ''} ${field.name})',
                );
            });
          }),
        );
    });

    writeSpec(applyExt);
  }
}
