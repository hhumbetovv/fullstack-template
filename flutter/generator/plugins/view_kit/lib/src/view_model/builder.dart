import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:common_tooling/tooling.dart';
import 'package:gen_core/base.dart';
import 'package:gen_view_kit/src/view_model/factory.dart';
import 'package:gen_view_kit/src/view_model/resolver.dart';
import 'package:glob/glob.dart';
import 'package:processor/public.dart';

class ViewModelBuilder extends BaseBuilder<ViewModelConfig, ClassElement2> {
  ViewModelBuilder({super.options})
    : super(
        name: 'view_model',
        annotation: ViewModel,
        resolver: ViewModelResolver(),
        buildFactory: ViewModelFactory(),
        allowSyntaxErrors: true,
      );

  final EffectCache _effectCache = EffectCache();

  @override
  Future<void> build(BuildStep buildStep) async {
    await _consumeEffectAssets(buildStep);
    await super.build(buildStep);
  }

  @override
  Map<String, dynamic>? toJson(ViewModelConfig? config) => config?.toJson();

  @override
  ViewModelConfig fromJson(Map<String, dynamic> json) => ViewModelConfig.fromJson(json);

  @override
  int calculateUpdatableHash(CompilationUnit unit) {
    var hash = 0;

    for (final clazz in unit.declarations.whereType<ClassDeclaration>()) {
      if (clazz.metadata.any((annotation) => annotation.contains(ViewModel))) {
        hash ^= clazz.name.hashCode;

        for (final method in clazz.members.whereType<MethodDeclaration>()) {
          if (method.metadata.any((annotation) => annotation.contains(Intent))) {
            hash ^= method.hashCode;
          }
        }

        hash ^= _effectHash(clazz.name.lexeme);
      }

      if (clazz.metadata.any((annotation) {
        final isView = annotation.contains(View);
        final isProvider = annotation.contains(Provider);

        return isView || isProvider;
      })) {
        hash ^= clazz.name.hashCode;

        for (final method in clazz.members.whereType<MethodDeclaration>()) {
          if (method.metadata.any((annotation) => annotation.contains(Effect))) {
            hash ^= method.hashCode;
          }
        }
      }
    }

    return hash;
  }

  Future<void> _consumeEffectAssets(BuildStep buildStep) async {
    final assets = buildStep.findAssets(Glob('**/*.view_effect.json'));
    await for (final asset in assets) {
      if (!await buildStep.canRead(asset)) continue;
      await buildStep.readAsString(asset);
    }
  }

  int _effectHash(String viewModelName) {
    try {
      final effects = _effectCache.readForViewModel(viewModelName);
      var hash = 0;
      for (final effect in effects) {
        hash ^= effect.view.hashCode;
        hash ^= effect.method.name.hashCode;
        for (final param in effect.method.params) {
          hash ^= param.name.hashCode;
          hash ^= param.type.hashCode;
        }
      }
      return hash;
    } on Object {
      return 0;
    }
  }
}

extension on Annotation {
  bool contains(Type type) {
    return toSource().toLowerCase().contains('$type'.toLowerCase());
  }
}
