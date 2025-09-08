import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:gen_core/base.dart';
import 'package:processor/processor.dart';

import 'factory.dart';
import 'resolver.dart';

class DataBuilder extends BaseBuilder<DataConfig, ClassElement2> {
  DataBuilder({
    super.options,
    super.name = 'data',
  }) : super(
         allowSyntaxErrors: true,
         resolver: DataResolver(),
         buildFactory: DataFactory(),
         annotation: Data,
       );

  @override
  int calculateUpdatableHash(CompilationUnit unit) {
    return 0;
  }

  @override
  DataConfig fromJson(Map<String, dynamic> json) => DataConfig.fromJson(json);

  @override
  Map<String, dynamic>? toJson(DataConfig? config) => config?.toJson();
}
