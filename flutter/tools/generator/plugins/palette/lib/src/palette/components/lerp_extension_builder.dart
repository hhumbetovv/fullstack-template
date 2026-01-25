import 'package:code_builder/code_builder.dart';
import 'package:processor/public.dart';

class PaletteLerpBuilder {
  PaletteLerpBuilder({
    required this.writeSpec,
  });

  final void Function(Spec spec) writeSpec;

  void writeLerpExtension(DataConfig config) {
    final lerpParams = buildInvocationParams(config.fields);
    final extension = Extension((extDef) {
      extDef
        ..name = '${config.name}Lerp'
        ..on = refer(config.name)
        ..methods.add(
          Method((methodDef) {
            methodDef
              ..returns = refer(config.name)
              ..name = 'lerp'
              ..requiredParameters.addAll([
                Parameter((paramDef) {
                  paramDef
                    ..type = refer(config.name)
                    ..name = 'other';
                }),
                Parameter((paramDef) {
                  paramDef
                    ..type = refer('$double')
                    ..name = 't';
                }),
              ])
              ..body = Code('return ${config.name}($lerpParams);');
          }),
        );
    });

    writeSpec(extension);
  }

  String buildInvocationParams(List<FieldConfig> fields) {
    return fields
        .map(
          (param) {
            final fieldType = param.type.replaceAll('?', '');
            if (fieldType == 'Color' || fieldType == 'LinearGradient') {
              return '${param.name}: $fieldType.lerp(${param.name}, other.${param.name}, t) ?? other.${param.name},';
            }
            if (fieldType.contains('Palette')) {
              return '${param.name}: ${param.name}.lerp(other.${param.name}, t),';
            }
            return '${param.name}: other.${param.name},';
          },
        )
        .join('\n');
  }
}
