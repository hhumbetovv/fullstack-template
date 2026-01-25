import 'package:code_builder/code_builder.dart';
import 'package:gen_core/constants.dart';
import 'package:gen_view_kit/src/view/factory.dart';

class ProviderFactory extends ViewFactory {
  @override
  String get suffix => 'Provider';

  @override
  Method? get buildView => null;

  @override
  String get stateType => Strings.singleChildStateType;

  @override
  String get statelessType => Strings.singleChildStatelessWidgetType;

  @override
  String get statefulType => Strings.singleChildStatefulWidgetType;

  @override
  String get bodyChild => 'child ?? const SizedBox.shrink()';

  @override
  Method createBuildMethod(Code body) {
    return Method((methodDef) {
      methodDef
        ..annotations.add(refer('override'))
        ..returns = refer(Strings.widgetType)
        ..name = 'buildWithChild'
        ..requiredParameters.addAll([
          Parameter((paramDef) {
            paramDef
              ..type = refer(Strings.contextType)
              ..name = 'context';
          }),
          Parameter((paramDef) {
            paramDef
              ..type = refer('${Strings.widgetType}?')
              ..name = 'child';
          }),
        ])
        ..body = body;
    });
  }

  @override
  Constructor get viewConstructor => super.viewConstructor.rebuild((constDef) {
    constDef.optionalParameters.add(
      Parameter((paramDef) {
        paramDef
          ..named = true
          ..name = 'child'
          ..toSuper = true;
      }),
    );
  });
}
