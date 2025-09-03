import 'package:analyzer/dart/element/element2.dart';
import 'package:generator/src/base/base_factory.dart';
import 'package:generator/src/base/base_resolver.dart';
import 'package:generator/src/builders/data/builder.dart';
import 'package:generator/src/builders/palette/factory.dart';
import 'package:generator/src/builders/palette/resolver.dart';
import 'package:processor/processor.dart';

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
