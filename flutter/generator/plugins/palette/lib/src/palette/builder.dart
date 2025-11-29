import 'package:analyzer/dart/element/element2.dart';
import 'package:gen_core/base.dart';
import 'package:gen_data/builder.dart';
import 'package:gen_palette/src/palette/factory.dart';
import 'package:gen_palette/src/palette/resolver.dart';
import 'package:processor/public.dart';

class PaletteBuilder extends DataBuilder {
  PaletteBuilder({
    super.options,
  }) : super(
         name: 'palette',
       );

  @override
  BaseResolver<DataConfig, ClassElement2> get resolver => PaletteResolver();

  @override
  BaseFactory<DataConfig> get buildFactory => PaletteFactory();

  @override
  Type get annotation => PaletteAnnotation;
}
