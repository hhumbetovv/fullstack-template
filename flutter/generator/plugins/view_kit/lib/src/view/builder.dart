import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:common_tooling/tooling.dart';
import 'package:gen_core/base.dart';
import 'package:gen_view_kit/src/shared/effect_cache_adapter.dart';
import 'package:gen_view_kit/src/view/factory.dart';
import 'package:gen_view_kit/src/view/resolver.dart';
import 'package:processor/public.dart';
import 'package:source_gen/source_gen.dart';

class ViewBuilder extends BaseBuilder<ViewConfig, ClassElement2> {
  ViewBuilder({
    super.options,
    super.name = 'view',
  }) : _effectCacheAdapter = const EffectCacheAdapter(),
       super(
         allowSyntaxErrors: true,
         annotation: View,
         buildFactory: ViewFactory(),
         resolver: ViewResolver(),
       );

  final EffectCacheAdapter _effectCacheAdapter;

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

    final cachedEffects = _effectCacheAdapter.toCachedEffects(
      viewConfig.effects,
    );

    EffectCache().upsertViewEffects(
      viewClassName: '${viewConfig.name}$suffix',
      effects: cachedEffects,
    );

    return viewConfig;
  }

  @override
  Map<String, dynamic>? toJson(ViewConfig? config) => config?.toJson();
}
