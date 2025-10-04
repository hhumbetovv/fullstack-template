// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkResponse<T> _$NetworkResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => NetworkResponse<T>(
  isSuccess: json['success'] as bool? ?? true,
  message: json['message'] as String?,
  action: json['action'] as String?,
  data: _$nullableGenericFromJson(json['data'], fromJsonT),
  errors:
      (json['errors'] as List<dynamic>?)?.map((e) => e as String?).toList() ??
      const [],
);

Map<String, dynamic> _$NetworkResponseToJson<T>(
  NetworkResponse<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'success': instance.isSuccess,
  'message': instance.message,
  'action': instance.action,
  'data': _$nullableGenericToJson(instance.data, toJsonT),
  'errors': instance.errors,
};

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) => input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) => input == null ? null : toJson(input);
