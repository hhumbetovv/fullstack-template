import 'package:code_builder/code_builder.dart';
import 'package:processor/public.dart';

class ViewClassBuilder {
  ViewClassBuilder({
    required this.writeSpec,
    required this.suffix,
    required this.statelessType,
  });

  final void Function(Spec spec) writeSpec;
  final String suffix;
  final String statelessType;

  void write({
    required ViewConfig config,
    required Constructor viewConstructor,
    required Method viewModelFactory,
    required Method baseInitState,
    required Method baseDispose,
    required Method builderMethod,
    required Iterable<Method> effectMethods,
    required Method? buildView,
    required Method buildMethod,
  }) {
    final viewName = '_${config.name}$suffix';
    final viewClass = Class((classDef) {
      classDef
        ..abstract = true
        ..name = viewName
        ..extend = refer(statelessType)
        ..implements.add(refer('BaseView'))
        ..constructors.add(viewConstructor)
        ..methods.addAll([
          viewModelFactory,
          baseInitState,
          baseDispose,
          builderMethod,
          ...effectMethods,
          if (buildView != null) buildView,
          buildMethod,
        ]);
    });

    writeSpec(viewClass);
  }
}
