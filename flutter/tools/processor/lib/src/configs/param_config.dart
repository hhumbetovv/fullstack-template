import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'param_config.g.dart';

@immutable
@JsonSerializable()
final class ParamConfig {
  const ParamConfig({
    required this.name,
    required this.type,
  });

  factory ParamConfig.fromJson(Map<String, dynamic> json) {
    return _$ParamConfigFromJson(json);
  }

  final String name;
  final String type;

  Map<String, dynamic> toJson() {
    return _$ParamConfigToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ParamConfig && name == other.name && type == other.type;
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      name,
      type,
    );
  }
}
