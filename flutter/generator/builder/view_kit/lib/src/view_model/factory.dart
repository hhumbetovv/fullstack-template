import 'package:code_builder/code_builder.dart';
import 'package:gen_core/base.dart';
import 'package:gen_core/constants.dart';
import 'package:gen_core/extensions.dart';
import 'package:processor/public.dart';

class ViewModelFactory extends BaseFactory<ViewModelConfig> {
  @override
  void build(ViewModelConfig config) {
    // ! State
    if (config.state.typeName == null) {
      buffer.writeln('typedef ${config.name}State = ${Strings.unitType};\n');
    } else if (config.state.typeName != '${config.name}State') {
      buffer.writeln('typedef ${config.name}State = ${config.state.typeName};\n');
    }

    // ! Intents
    generateContractClass(
      config.name,
      'Intent',
      config.intents,
      additionalMethods: [
        intentDispatchMethod(config),
      ],
    );

    //! Effects
    generateContractClass(
      config.name,
      'Effect',
      config.effects.map((effect) => effect.method).toList(),
    );

    //! Base View Model
    generateBaseClass(config);

    generateContractMethods(config);
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

  void generateContractClass(
    String baseName,
    String contractName,
    List<MethodConfig> methods, {
    List<Method> additionalMethods = const [],
  }) {
    if (methods.isEmpty) {
      buffer.writeln('typedef $baseName$contractName = ${Strings.unitType};\n');
    } else {
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
                ..removeWhere((param) {
                  return param.type == Strings.contextType && contractName == 'Effect';
                });
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
                  ..redirect = refer('$prefix$baseName${method.name.normalize().capitalize()}');
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
          ..removeWhere((param) {
            return param.type == Strings.contextType && contractName == 'Effect';
          });
        final contractSubClass = Class((classDec) {
          final subClassName = '$prefix$baseName${method.name.normalize().capitalize()}';
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
                    .map((param) {
                      return '${param.name}: \$${param.name}';
                    })
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

  void generateBaseClass(ViewModelConfig config) {
    final intents = config.intents.map((method) {
      final intentName = '${config.name}${method.name.normalize().capitalize()}';
      return '_$intentName() => (this as ${config.name}ViewModel).${method.name}('
          '${method.params.map((param) => 'intent.${param.name}').join(',')}'
          '),';
    }).join();

    final baseViewModel = Class((classDef) {
      classDef
        ..abstract = true
        ..name = '_${config.name}ViewModel'
        ..extend = refer(
          '${Strings.baseViewModelType}<${config.name}Intent, ${config.name}State, ${config.name}Effect>',
        )
        ..constructors.add(Constructor())
        ..methods.addAll([
          if (config.state.typeName == null)
            Method((methodDef) {
              methodDef
                ..name = 'initialState'
                ..annotations.add(refer('override'))
                ..type = MethodType.getter
                ..lambda = true
                ..returns = refer('Unit')
                ..body = const Code('Unit()');
            }),
          if (config.intents.isNotEmpty) ...[
            Method.returnsVoid((methodDef) {
              methodDef
                ..name = '_postIntent'
                ..lambda = true
                ..body = const Code('super.postIntent(intent)')
                ..requiredParameters.add(
                  Parameter((paramDef) {
                    paramDef
                      ..name = 'intent'
                      ..type = refer('${config.name}Intent');
                  }),
                );
            }),
            Method((methodDef) {
              methodDef
                ..annotations.add(refer('override'))
                ..returns = refer('Future<void>')
                ..name = 'onIntentUpdate'
                ..modifier = MethodModifier.async
                ..requiredParameters.add(
                  Parameter((paramDef) {
                    paramDef
                      ..name = 'intent'
                      ..type = refer('${config.name}Intent');
                  }),
                )
                ..body = Code(
                  'return switch (intent) {'
                  '$intents'
                  '};',
                );
            }),
          ],
        ]);
    });

    writeSpec(baseViewModel);
  }

  void generateContractMethods(ViewModelConfig config) {
    if (config.state.typeName != Strings.unitType && config.state.typeName != null) {
      final selectMethod = Method((methodDef) {
        methodDef
          ..name = '${config.name.unCapitalize()}Select'
          ..returns = refer('Value')
          ..types.add(refer('Value'))
          ..requiredParameters.addAll([
            Parameter((paramDef) {
              paramDef
                ..name = 'context'
                ..type = refer('BuildContext');
            }),
            Parameter((paramDef) {
              paramDef
                ..name = 'selector'
                ..type = refer('Value Function(${config.name}State state)');
            }),
          ])
          ..body = Code(
            'return context.select<${config.name}ViewModel, Value>((viewModel) => selector(viewModel.state));',
          );
      });

      writeSpec(selectMethod);

      final stateMethod = Method((methodDef) {
        methodDef
          ..name = '${config.name.unCapitalize()}State'
          ..returns = refer('${config.name}State')
          ..requiredParameters.add(
            Parameter((paramDef) {
              paramDef
                ..name = 'context'
                ..type = refer('BuildContext');
            }),
          )
          ..optionalParameters.add(
            Parameter((paramDef) {
              paramDef
                ..named = true
                ..name = 'watch'
                ..defaultTo = const Code('false')
                ..type = refer('bool');
            }),
          )
          ..body = Code(
            'if(watch) return context.watch<${config.name}ViewModel>().state; '
            'return context.read<${config.name}ViewModel>().state;',
          );
      });

      writeSpec(stateMethod);
    }
  }
}
