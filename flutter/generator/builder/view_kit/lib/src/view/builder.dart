import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:gen_core/base.dart';
import 'package:gen_core/constants.dart';
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
  Future<ViewConfig?> onResolve(LibraryReader library, BuildStep buildStep, int stepHash) async {
    final viewConfig = await super.onResolve(library, buildStep, stepHash);
    if (viewConfig == null) return null;

    addToCache(
      viewConfig.effects,
      '${viewConfig.name}$suffix',
    );

    return viewConfig;
  }

  void addToCache(
    List<EffectConfig> effects,
    String className,
  ) {
    final cacheFile = File(Strings.effectsPath);
    if (!cacheFile.existsSync()) {
      cacheFile.createSync(recursive: true);
    }

    final existingData = readCache(cacheFile)
      ..removeWhere((effectConfig) => effectConfig.view == className)
      ..addAll(effects);

    cacheFile.writeAsStringSync(
      jsonEncode(
        existingData.map((effectConfig) {
          return effectConfig.toJson();
        }).toList(),
      ),
    );
  }

  List<EffectConfig> readCache(File cacheFile) {
    if (!cacheFile.existsSync()) return [];
    try {
      final content = cacheFile.readAsStringSync();
      return List<Map<String, dynamic>>.from(jsonDecode(content) as Iterable).map((json) {
        return EffectConfig.fromJson(json);
      }).toList();
    } on Exception catch (_) {
      return [];
    }
  }

  @override
  Map<String, dynamic>? toJson(ViewConfig? config) => config?.toJson();
}
