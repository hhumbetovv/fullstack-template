import 'package:analyzer/dart/element/element2.dart';
import 'package:generator/src/base/base_factory.dart';
import 'package:generator/src/base/base_resolver.dart';
import 'package:generator/src/builders/provider/factory.dart';
import 'package:generator/src/builders/provider/resolver.dart';
import 'package:generator/src/builders/view/builder.dart';
import 'package:processor/processor.dart';

class ProviderBuilder extends ViewBuilder {
  ProviderBuilder({
    super.options,
    super.name = 'provider',
  });

  @override
  Type get annotation => Provider;

  @override
  BaseFactory<ViewConfig> get buildFactory => ProviderFactory();

  @override
  BaseResolver<ViewConfig, ClassElement2> get resolver => ProviderResolver();

  @override
  String get suffix => 'Provider';
}
