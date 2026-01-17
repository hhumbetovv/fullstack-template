import 'dart:convert';

import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:common_tooling/tooling.dart';
import 'package:gen_view_kit/src/shared/effect_cache_adapter.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

class ViewEffectVmBuilder implements Builder {
  ViewEffectVmBuilder()
    : buildExtensions = const {
        '.dart': ['.view_effect.json'],
      };

  final EffectCache _effectCache = EffectCache();
  final EffectCacheAdapter _effectCacheAdapter = const EffectCacheAdapter();

  @override
  final Map<String, List<String>> buildExtensions;

  @override
  Future<void> build(BuildStep buildStep) async {
    if (!await buildStep.resolver.isLibrary(buildStep.inputId)) return;
    final library = await buildStep.resolver.libraryFor(
      buildStep.inputId,
      allowSyntaxErrors: true,
    );
    final reader = LibraryReader(library);
    final viewModelName = _resolveViewModelName(reader);
    if (viewModelName == null) return;

    await _consumeViewEffects(buildStep);

    final cached = _effectCache.readForViewModel(viewModelName);
    final effects = _effectCacheAdapter.fromCachedEffects(cached);
    final outputId = buildStep.inputId.changeExtension('.view_effect.json');
    final payload = effects.map((effect) => effect.toJson()).toList();
    final encoded = jsonEncode(payload);
    if (await buildStep.canRead(outputId)) {
      final existing = await buildStep.readAsString(outputId);
      if (existing == encoded) {
        return;
      }
    }
    await buildStep.writeAsString(outputId, encoded);
  }

  String? _resolveViewModelName(LibraryReader reader) {
    for (final clazz in reader.classes.whereType<ClassElement2>()) {
      for (final annotation in clazz.metadata2.annotations) {
        final value = annotation.computeConstantValue();
        if (value?.type?.getDisplayString() == 'ViewModel') {
          return clazz.displayName;
        }
      }
    }
    return null;
  }

  Future<void> _consumeViewEffects(BuildStep buildStep) async {
    final outputId = buildStep.inputId.changeExtension('.view_effect.json');
    final assets = buildStep.findAssets(Glob('**/*.view_effect.json'));
    await for (final asset in assets) {
      if (asset == outputId) continue;
      if (!await buildStep.canRead(asset)) continue;
      await buildStep.readAsString(asset);
    }
  }
}
