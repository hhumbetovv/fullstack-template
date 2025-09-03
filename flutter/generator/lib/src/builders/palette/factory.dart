import 'package:code_builder/code_builder.dart';
import 'package:generator/src/builders/data/factory.dart';
import 'package:processor/processor.dart';

class PaletteFactory extends DataFactory {
  @override
  bool get generateToString => false;

  @override
  bool get generateApply => false;

  @override
  bool get generateEquatable => false;

  @override
  void build(DataConfig config) {
    super.build(config);

    createLerp(config);
  }

  void createLerp(DataConfig config) {
    final lerpParams = config.fields.map((param) {
      final fieldType = param.type.replaceAll('?', '');
      if (fieldType == 'Color' || fieldType == 'LinearGradient') {
        return '${param.name}: $fieldType.lerp(${param.name}, other.${param.name}, t) ?? other.${param.name},';
      }
      if (fieldType.contains('Palette')) {
        return '${param.name}: ${param.name}.lerp(other.${param.name}, t) ?? other.${param.name},';
      }
      return '${param.name}: other.${param.name},';
    }).join('\n');

    final applyExt = Extension((extDef) {
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

    writeSpec(applyExt);
  }
}
