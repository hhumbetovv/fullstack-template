class CachedEffectMethodParam {
  const CachedEffectMethodParam({
    required this.name,
    required this.type,
  });

  factory CachedEffectMethodParam.fromJson(Map<String, dynamic> json) {
    return CachedEffectMethodParam(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
    );
  }

  final String name;
  final String type;

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
  };
}

class CachedEffectMethod {
  const CachedEffectMethod({
    required this.name,
    required this.params,
  });

  factory CachedEffectMethod.fromJson(Map<String, dynamic> json) {
    final params = (json['params'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CachedEffectMethodParam.fromJson)
        .toList();
    return CachedEffectMethod(
      name: json['name'] as String? ?? '',
      params: params,
    );
  }

  final String name;
  final List<CachedEffectMethodParam> params;

  Map<String, dynamic> toJson() => {
    'name': name,
    'params': params.map((param) => param.toJson()).toList(),
  };
}

class CachedEffect {
  const CachedEffect({
    required this.view,
    required this.viewModel,
    required this.method,
  });

  factory CachedEffect.fromJson(Map<String, dynamic> json) {
    return CachedEffect(
      view: json['view'] as String? ?? '',
      viewModel: json['viewModel'] as String? ?? '',
      method: CachedEffectMethod.fromJson(
        json['method'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  final String view;
  final String viewModel;
  final CachedEffectMethod method;

  Map<String, dynamic> toJson() => {
    'view': view,
    'viewModel': viewModel,
    'method': method.toJson(),
  };
}
