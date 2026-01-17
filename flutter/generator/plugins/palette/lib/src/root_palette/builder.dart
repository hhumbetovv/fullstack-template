import 'package:analyzer/dart/element/element2.dart';
import 'package:gen_core/base.dart';
import 'package:gen_data/builder.dart';
import 'package:gen_palette/src/root_palette/factory.dart';
import 'package:gen_palette/src/root_palette/resolver.dart';
import 'package:processor/public.dart';

class RootPaletteBuilder extends DataBuilder {
  RootPaletteBuilder({
    super.options,
  }) : super(
         name: 'rootPalette',
       );

  @override
  BaseResolver<DataConfig, ClassElement2> get resolver => RootPaletteResolver();

  @override
  BaseFactory<DataConfig> get buildFactory => RootPaletteFactory();

  @override
  Type get annotation => RootPalette;
}
