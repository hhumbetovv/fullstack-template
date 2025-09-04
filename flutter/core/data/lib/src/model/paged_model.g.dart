// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paged_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PagedModel<T> _$PagedModelFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => PagedModel<T>(
  content: (json['content'] as List<dynamic>).map(fromJsonT).toList(),
  number: (json['number'] as num).toInt(),
  size: (json['size'] as num).toInt(),
  totalElements: (json['totalElements'] as num).toInt(),
  totalPages: (json['totalPages'] as num).toInt(),
  firstPage: json['firstPage'] as bool,
  lastPage: json['lastPage'] as bool,
);
