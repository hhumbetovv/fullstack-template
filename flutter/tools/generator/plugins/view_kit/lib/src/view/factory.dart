import 'package:code_builder/code_builder.dart';
import 'package:gen_core/base.dart';
import 'package:gen_core/constants.dart';
import 'package:gen_core/extensions.dart';
import 'package:processor/public.dart';

import 'components/effect_methods_builder.dart';
import 'components/view_body_builder.dart';
import 'components/view_class_builder.dart';

class ViewFactory extends BaseFactory<ViewConfig> {
  String get suffix => 'View';

  String get stateType => Strings.stateType;

  String get statelessType => Strings.statelessWidgetType;

  String get statefulType => Strings.statefulWidgetType;

  String get bodyChild => 'buildView(ctx)';

  Method? get buildView {
    return Method((methodDef) {
      methodDef
        ..returns = refer(Strings.widgetType)
        ..name = 'buildView'
        ..requiredParameters.add(
          Parameter((paramDef) {
            paramDef
              ..type = refer(Strings.contextType)
              ..name = 'context';
          }),
        );
    });
  }

  Constructor get viewConstructor {
    return Constructor((constDef) {
      constDef
        ..constant = true
        ..optionalParameters.add(
          Parameter((paramDef) {
            paramDef
              ..named = true
              ..name = 'key'
              ..toSuper = true;
          }),
        );
    });
  }

  @override
  void build(ViewConfig config) {
    buffer.writeln('// ignore_for_file: unreachable_switch_case');

    final effectMap = getEffectMap(config.effects);
    final effectMethods = EffectMethodsBuilder(suffix: suffix).build(
      config.name,
      effectMap,
    );
    final body =
        ViewBodyBuilder(
          bodyChild: bodyChild,
          effectMethodName: getEffectMethodName,
        ).build(
          config.name,
          effectMap,
          config.isStateful,
        );

    ViewClassBuilder(
      writeSpec: writeSpec,
      suffix: suffix,
      statelessType: statelessType,
    ).write(
      config: config,
      viewConstructor: viewConstructor,
      viewModelFactory: factory(config.name, config.customFactory),
      baseInitState: baseInitState,
      baseDispose: baseDispose,
      builderMethod: builderMethod,
      effectMethods: effectMethods,
      buildView: buildView,
      buildMethod: createBuildMethod(body),
    );
  }

  Map<String, List<MethodConfig>> getEffectMap(List<EffectConfig> effects) {
    return effects.fold<Map<String, List<MethodConfig>>>({}, (
      previousValue,
      effect,
    ) {
      final map = previousValue;
      if (map[effect.viewModel] == null) map[effect.viewModel] = [];
      map[effect.viewModel]?.add(effect.method);
      return map;
    });
  }

  Method get baseInitState {
    return Method.returnsVoid((methodDef) {
      methodDef
        ..name = 'initState'
        ..body = const Code('')
        ..annotations.add(refer('override'))
        ..requiredParameters.add(
          Parameter((paramDef) {
            paramDef
              ..type = refer(Strings.contextType)
              ..name = 'context';
          }),
        );
    });
  }

  Method get baseDispose {
    return Method.returnsVoid((methodDef) {
      methodDef
        ..name = 'dispose'
        ..body = const Code('')
        ..annotations.add(refer('override'))
        ..requiredParameters.add(
          Parameter((paramDef) {
            paramDef
              ..type = refer(Strings.contextType)
              ..name = 'context';
          }),
        );
    });
  }

  Method get builderMethod {
    return Method((methodDef) {
      methodDef
        ..returns = refer(Strings.widgetType)
        ..name = 'builder'
        ..optionalParameters.addAll([
          Parameter((paramDef) {
            paramDef
              ..type = refer(Strings.contextType)
              ..named = true
              ..required = true
              ..name = 'context';
          }),
          Parameter((paramDef) {
            paramDef
              ..type = refer(Strings.widgetType)
              ..named = true
              ..required = true
              ..name = 'child';
          }),
        ])
        ..body = const Code('return child;');
    });
  }

  Method factory(String baseName, bool isCustom) {
    final viewModelName = '${baseName}ViewModel';
    return Method((methodDef) {
      methodDef
        ..returns = refer(viewModelName)
        ..name = 'viewModelFactory'
        ..requiredParameters.add(
          Parameter((paramDef) {
            paramDef
              ..type = refer(Strings.contextType)
              ..name = 'context';
          }),
        );
      if (!isCustom) {
        methodDef.body = Code('return $viewModelName();');
      }
    });
  }

  Method createBuildMethod(Code body) {
    return Method((methodDef) {
      methodDef
        ..annotations.add(refer('override'))
        ..returns = refer(Strings.widgetType)
        ..name = 'build'
        ..requiredParameters.add(
          Parameter((paramDef) {
            paramDef
              ..type = refer(Strings.contextType)
              ..name = 'context';
          }),
        )
        ..body = body;
    });
  }

  String getEffectMethodName(String name) {
    return '_on${name.capitalize()}EffectUpdate';
  }
}
