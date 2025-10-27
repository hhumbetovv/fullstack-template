import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:common_tooling/tooling.dart';
import 'package:gen_core/base.dart';
import 'package:gen_view_kit/src/view/factory.dart';
import 'package:gen_view_kit/src/view/resolver.dart';
import 'package:processor/public.dart';
import 'package:source_gen/source_gen.dart';

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
  Future<ViewConfig?> onResolve(
    LibraryReader library,
    BuildStep buildStep,
    int stepHash,
  ) async {
    final viewConfig = await super.onResolve(library, buildStep, stepHash);
    if (viewConfig == null) return null;

    final cachedEffects = viewConfig.effects.map(_toCachedEffect).toList();

    EffectCache().upsertViewEffects(
      viewClassName: '${viewConfig.name}$suffix',
      effects: cachedEffects,
    );

    return viewConfig;
  }

  CachedEffect _toCachedEffect(EffectConfig effect) {
    return CachedEffect(
      view: effect.view,
      viewModel: effect.viewModel,
      method: CachedEffectMethod(
        name: effect.method.name,
        params: effect.method.params
            .map(
              (param) => CachedEffectMethodParam(
                name: param.name,
                type: param.type,
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Map<String, dynamic>? toJson(ViewConfig? config) => config?.toJson();
}
