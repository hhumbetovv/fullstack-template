import 'package:code_builder/code_builder.dart';
import 'package:gen_core/base.dart';
import 'package:gen_core/constants.dart';
import 'package:gen_core/extensions.dart';
import 'package:processor/processor.dart';

class ViewFactory extends BaseFactory<ViewConfig> {
  String get suffix => 'View';

  String get stateType => Strings.stateType;

  String get statelessType => Strings.statelessWidgetType;

  String get statefulType => Strings.statefulWidgetType;

  String get bodyChild => 'buildView(ctx)';

  @override
  void build(ViewConfig config) {
    buffer.writeln('// ignore_for_file: unreachable_switch_case');

    final effectMap = getEffectMap(config.effects);

    final effectMethods = getEffectMethods(
      config.name,
      effectMap,
    );

    final body = createClassBody(
      config.name,
      effectMap,
      config.isStateful,
    );

    final viewName = '_${config.name}$suffix';
    final viewClass = Class((classDef) {
      final buildView = this.buildView;

      classDef
        ..abstract = true
        ..name = viewName
        ..extend = refer(statelessType)
        ..implements.add(refer('BaseView'))
        ..constructors.add(viewConstructor)
        ..methods.addAll([
          factory(config.name, config.customFactory),
          baseInitState,
          baseDispose,
          builderMethod,
          ...effectMethods,
          ?buildView,
          createBuildMethod(body),
        ]);
    });

    writeSpec(viewClass);
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

  Method createState(String name) {
    return Method((methodDef) {
      methodDef
        ..annotations.add(refer('override'))
        ..returns = refer('$stateType<$name>')
        ..name = 'createState'
        ..body = Code('return ${name}State();');
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

  Map<String, List<MethodConfig>> getEffectMap(List<EffectConfig> effects) {
    return effects.fold<Map<String, List<MethodConfig>>>({}, (previousValue, effect) {
      final map = previousValue;
      if (map[effect.viewModel] == null) map[effect.viewModel] = [];
      map[effect.viewModel]?.add(effect.method);
      return map;
    });
  }

  Iterable<Method> getEffectMethods(
    String name,
    Map<String, List<MethodConfig>> map,
  ) {
    final viewName = '$name$suffix';
    return map.entries.map((entry) {
      final MapEntry(key: viewModel, value: methods) = entry;

      final baseName = viewModel.trimBefore(Strings.viewModelType);
      const effectParamName = 'effect';
      const contextParamName = 'context';

      final methodBody = methods.map((method) {
        final effectClass = '$baseName${method.name.normalize().capitalize()}';

        final params = method.params
            .map((param) {
              if (param.type == Strings.contextType) return contextParamName;
              return '$effectParamName.${param.name}';
            })
            .join(',');

        return '$effectClass() => (this as $viewName).${method.name}($params),';
      }).join();

      return Method.returnsVoid((methodDef) {
        methodDef
          ..name = getEffectMethodName(baseName)
          ..requiredParameters.addAll([
            Parameter((paramDef) {
              paramDef
                ..name = contextParamName
                ..type = refer(Strings.contextType);
            }),
            Parameter((paramDef) {
              paramDef
                ..name = effectParamName
                ..type = refer('${baseName}Effect');
            }),
          ])
          ..body = Code(
            'return switch(effect){'
            '$methodBody'
            '_ => null, '
            '};',
          );
      });
    });
  }

  Code createClassBody(
    String baseName,
    Map<String, List<MethodConfig>> map,
    bool isStateful,
  ) {
    var child = bodyChild;

    if (isStateful) {
      child =
          '''
        StatefulWrapper(
          initState: initState,
          dispose: dispose,
          child: $child
        )
        ''';
    }

    for (final entry in map.entries) {
      final baseName = entry.key.trimBefore('viewmodel');

      child =
          '''
        ViewModelListener<${entry.key}, ${baseName}Effect>(
          onEffectUpdate: ${getEffectMethodName(baseName)},
          child: $child,
        )
        ''';
    }
    final builder = 'Builder(builder: (ctx) { return $child; })';

    return Code(
      'return builder(context: context, '
      'child: ViewModelProvider<${baseName}ViewModel, ${baseName}Effect>( '
      'create: viewModelFactory, '
      'child: $builder, '
      ')'
      ');',
    );
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
