import 'package:analyzer/dart/element/element.dart';
import 'package:gen_core/base.dart';
import 'package:gen_view_kit/src/provider/factory.dart';
import 'package:gen_view_kit/src/provider/resolver.dart';
import 'package:gen_view_kit/src/view/builder.dart';
import 'package:processor/public.dart';

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
  BaseResolver<ViewConfig, ClassElement> get resolver => ProviderResolver();

  @override
  String get suffix => 'Provider';
}
