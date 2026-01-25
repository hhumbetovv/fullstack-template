import 'package:json_annotation/json_annotation.dart';
import 'package:processor/src/configs/field_config.dart';

part 'data_config.g.dart';

@JsonSerializable()
class DataConfig {
  const DataConfig({
    required this.name,
    required this.isFactory,
    required this.fields,
    this.generics = const [],
  });

  factory DataConfig.fromJson(Map<String, dynamic> json) {
    return _$DataConfigFromJson(json);
  }

  final String name;
  final bool isFactory;
  final List<FieldConfig> fields;
  final List<String> generics;

  Map<String, dynamic> toJson() {
    return _$DataConfigToJson(this);
  }
}
