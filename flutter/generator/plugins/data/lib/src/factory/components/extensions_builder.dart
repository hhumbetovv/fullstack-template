import 'package:code_builder/code_builder.dart';
import 'package:gen_core/extensions.dart';
import 'package:processor/public.dart';

class DataExtensionsBuilder {
  DataExtensionsBuilder({
    required this.writeSpec,
  });

  final void Function(Spec spec) writeSpec;

  void writeGetters(DataConfig config) {
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

  void writeCopy(DataConfig config) {
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
              ..body = Code(
                'return ${config.isFactory ? '_' : ''}${config.name}('
                '${config.fields.map((field) {
                  final name = field.name;
                  if (field.isNullable) {
                    return '$name: $name != null ? $name() : $ref.$name,';
                  }
                  return '$name: $name ?? $ref.$name,';
                }).join(' ')}'
                ');',
              );
          }),
        );
    });

    writeSpec(copyExt);
  }

  void writeApply(DataConfig config) {
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
