import 'package:code_builder/code_builder.dart';
import 'package:gen_core/constants.dart';
import 'package:gen_core/extensions.dart';
import 'package:processor/public.dart';

class ViewModelContractBuilder {
  ViewModelContractBuilder({
    required this.buffer,
    required this.writeSpec,
  });

  final StringBuffer buffer;
  final void Function(Spec spec) writeSpec;

  void writeStateTypedef(ViewModelConfig config) {
    if (config.state.typeName == null) {
      buffer.writeln('typedef ${config.name}State = ${Strings.unitType};\n');
    } else if (config.state.typeName != '${config.name}State') {
      buffer.writeln(
        'typedef ${config.name}State = ${config.state.typeName};\n',
      );
    }
  }

  void writeIntentContract(ViewModelConfig config) {
    _generateContractClass(
      baseName: config.name,
      contractName: 'Intent',
      methods: config.intents,
      additionalMethods: [intentDispatchMethod(config)],
    );
  }

  void writeEffectContract(ViewModelConfig config) {
    _generateContractClass(
      baseName: config.name,
      contractName: 'Effect',
      methods: config.effects.map((effect) => effect.method).toList(),
    );
  }

  Method intentDispatchMethod(ViewModelConfig config) {
    return Method.returnsVoid((methodDef) {
      methodDef
        ..name = 'dispatch'
        ..requiredParameters.add(
          Parameter((paramDef) {
            paramDef
              ..type = refer(Strings.contextType)
              ..name = 'context';
          }),
        )
        ..body = Code(
          'if(!context.mounted) return; '
          'context.read<${config.name}ViewModel>()._postIntent(this);',
        );
    });
  }

  void _generateContractClass({
    required String baseName,
    required String contractName,
    required List<MethodConfig> methods,
    List<Method> additionalMethods = const [],
  }) {
    if (methods.isEmpty) {
      buffer.writeln('typedef $baseName$contractName = ${Strings.unitType};\n');
      return;
    }

    final prefix = contractName == 'Effect' ? '' : '_';
    final contractClass = Class((classDec) {
      classDec
        ..sealed = true
        ..name = '$baseName$contractName'
        ..constructors.addAll([
          Constructor((constDec) {
            constDec.constant = true;
          }),
          ...methods.map((method) {
            final filteredParams = method.params
                .where(
                  (param) =>
                      !(param.type == Strings.contextType &&
                          contractName == 'Effect'),
                )
                .toList();
            return Constructor((constDec) {
              constDec
                ..constant = true
                ..factory = true
                ..name = method.name.normalize()
                ..requiredParameters.addAll(
                  filteredParams.map((param) {
                    return Parameter((paramDec) {
                      paramDec
                        ..name = param.name
                        ..type = refer(param.type);
                    });
                  }),
                )
                ..redirect = refer(
                  '$prefix$baseName${method.name.normalize().capitalize()}',
                );
            });
          }),
        ])
        ..methods.addAll(additionalMethods);
    });

    writeSpec(contractClass);

    final created = <String>{};

    for (final method in methods) {
      if (created.contains(method.name)) continue;

      final filteredParams = method.params
          .where(
            (param) =>
                !(param.type == Strings.contextType &&
                    contractName == 'Effect'),
          )
          .toList();
      final contractSubClass = Class((classDec) {
        final subClassName =
            '$prefix$baseName${method.name.normalize().capitalize()}';
        classDec
          ..name = subClassName
          ..modifier = ClassModifier.final$
          ..extend = refer('$baseName$contractName')
          ..methods.add(
            Method((methodDef) {
              methodDef
                ..annotations.add(refer('override'))
                ..returns = refer('String')
                ..name = 'toString';

              final fields = method.params
                  .map((param) => '${param.name}: \$${param.name}')
                  .join(', ');

              if (fields.isEmpty) {
                methodDef.body = Code("return '$subClassName';");
              } else {
                methodDef.body = Code("return '$subClassName { $fields }';");
              }
            }),
          )
          ..fields.addAll(
            filteredParams.map((param) {
              return Field((fieldDec) {
                fieldDec
                  ..modifier = FieldModifier.final$
                  ..name = param.name
                  ..type = refer(param.type);
              });
            }),
          )
          ..constructors.add(
            Constructor((constDec) {
              constDec
                ..constant = true
                ..requiredParameters.addAll(
                  filteredParams.map((param) {
                    return Parameter((paramDec) {
                      paramDec
                        ..name = param.name
                        ..toThis = true;
                    });
                  }),
                );
            }),
          );
      });

      writeSpec(contractSubClass);
      created.add(method.name);
    }
  }
}
