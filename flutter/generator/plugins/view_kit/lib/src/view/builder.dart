import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:gen_core/base.dart';
import 'package:gen_view_kit/src/view/factory.dart';
import 'package:gen_view_kit/src/view/resolver.dart';
import 'package:processor/public.dart';

class ViewBuilder extends BaseBuilder<ViewConfig, ClassElement2> {
  ViewBuilder({
    super.options,
    super.name = 'view',
  }) : super(
         allowSyntaxErrors: true,
         annotation: View,
         buildFactory: ViewFactory(),
         resolver: ViewResolver(),
       );

  @override
  ViewConfig fromJson(Map<String, dynamic> json) => ViewConfig.fromJson(json);

  @override
  int calculateUpdatableHash(CompilationUnit unit) {
    return 0;
  }

  String get suffix => 'View';

  @override
  Map<String, dynamic>? toJson(ViewConfig? config) => config?.toJson();
}
