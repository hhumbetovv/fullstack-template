import 'package:code_builder/code_builder.dart';
import 'package:gen_core/constants.dart';
import 'package:gen_core/extensions.dart';
import 'package:processor/public.dart';

class ViewModelBaseClassBuilder {
  ViewModelBaseClassBuilder({
    required this.writeSpec,
  });

  final void Function(Spec spec) writeSpec;

  void writeBaseClass(ViewModelConfig config) {
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
}
