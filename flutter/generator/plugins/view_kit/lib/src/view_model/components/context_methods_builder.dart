import 'package:code_builder/code_builder.dart';
import 'package:gen_core/constants.dart';
import 'package:gen_core/extensions.dart';
import 'package:processor/public.dart';

class ViewModelContextMethodsBuilder {
  ViewModelContextMethodsBuilder({
    required this.writeSpec,
  });

  final void Function(Spec spec) writeSpec;

  void writeContextMethods(ViewModelConfig config) {
    if (config.state.typeName == Strings.unitType || config.state.typeName == null) {
      return;
    }

    _writeSelectMethod(config);
    _writeStateMethod(config);
  }

  void _writeSelectMethod(ViewModelConfig config) {
    final method = Method((methodDef) {
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

    writeSpec(method);
  }

  void _writeStateMethod(ViewModelConfig config) {
    final method = Method((methodDef) {
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

    writeSpec(method);
  }
}
