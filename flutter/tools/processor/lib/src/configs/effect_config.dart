import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:processor/src/configs/method_config.dart';

part 'effect_config.g.dart';

@immutable
@JsonSerializable()
class EffectConfig {
  const EffectConfig({
    required this.view,
    required this.viewModel,
    required this.method,
  });

  factory EffectConfig.fromJson(Map<String, dynamic> json) {
    return _$EffectConfigFromJson(json);
  }

  final String view;
  final String viewModel;
  final MethodConfig method;

  Map<String, dynamic> toJson() {
    return _$EffectConfigToJson(this);
  }

  @override
  bool operator ==(Object other) {
    if (other is! EffectConfig ||
        other.viewModel != viewModel ||
        other.method.name.replaceAll('_', '') != method.name.replaceAll('_', '')) {
      return false;
    }

    final params = method.params.where((param) {
      return param.type != 'BuildContext';
    }).toList();

    final otherParams = other.method.params.where((param) {
      return param.type != 'BuildContext';
    }).toList();

    return _listEquals(params, otherParams);
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) {
      return b == null;
    }
    if (b == null || a.length != b.length) {
      return false;
    }
    if (identical(a, b)) {
      return true;
    }
    for (var index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      viewModel,
      method,
    );
  }
}
