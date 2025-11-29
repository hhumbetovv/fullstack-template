import 'package:common_tooling/tooling.dart';
import 'package:processor/public.dart';

/// Converts between builder-facing [EffectConfig] models and the cached
/// representations stored in [EffectCache].
class EffectCacheAdapter {
  const EffectCacheAdapter();

  List<CachedEffect> toCachedEffects(Iterable<EffectConfig> effects) {
    return effects.map(_toCachedEffect).toList();
  }

  List<EffectConfig> fromCachedEffects(Iterable<CachedEffect> effects) {
    return effects.map(_fromCachedEffect).toList();
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

  EffectConfig _fromCachedEffect(CachedEffect effect) {
    return EffectConfig(
      view: effect.view,
      viewModel: effect.viewModel,
      method: MethodConfig(
        name: effect.method.name,
        params: effect.method.params
            .map(
              (param) => ParamConfig(
                name: param.name,
                type: param.type,
              ),
            )
            .toList(),
      ),
    );
  }
}
