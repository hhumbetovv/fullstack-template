import 'package:code_builder/code_builder.dart';
import 'package:gen_core/extensions.dart';
import 'package:processor/public.dart';

class DataExtensionsBuilder {
  DataExtensionsBuilder({
    required this.writeSpec,
  });

  final void Function(Spec spec) writeSpec;

  void writeGetters(DataConfig config) {
    final genericsSuffix = _genericsSuffix(config.generics);
    final ref = config.isFactory
        ? '_self'
        : '(this as ${config.name}$genericsSuffix)';
    final getterExtension = Extension((extDef) {
      extDef
        ..name = '${!config.isFactory ? '_' : ''}${config.name}Getter'
        ..types.addAll(_typeParameters(config))
        ..on = _typeWithGenerics(
          '${!config.isFactory ? '_' : ''}${config.name}',
          config.generics,
        )
        ..methods.addAll(
          [
            if (config.isFactory)
              Method((methodDef) {
                methodDef
                  ..returns = _typeWithGenerics(
                    '_${config.name}',
                    config.generics,
                  )
                  ..type = MethodType.getter
                  ..name = '_self'
                  ..lambda = true
                  ..body = Code('this as _${config.name}$genericsSuffix');
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
    final genericsSuffix = _genericsSuffix(config.generics);
    final className = '${config.isFactory ? '_' : ''}${config.name}';
    final copyExt = Extension((extDef) {
      extDef
        ..name = '${config.name}Copy'
        ..types.addAll(_typeParameters(config))
        ..on = _typeWithGenerics(config.name, config.generics)
        ..methods.add(
          Method((methodDef) {
            methodDef
              ..returns = _typeWithGenerics(config.name, config.generics)
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
                'return $className$genericsSuffix('
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
        ..types.addAll(_typeParameters(config))
        ..on = _typeWithGenerics(config.name, config.generics)
        ..methods.addAll(
          config.fields.map((field) {
            return Method((methodDef) {
              methodDef
                ..returns = _typeWithGenerics(config.name, config.generics)
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
