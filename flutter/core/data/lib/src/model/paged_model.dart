import 'package:core_domain/entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'paged_model.g.dart';

@JsonSerializable(genericArgumentFactories: true, createToJson: false)
class PagedModel<T> implements Paged<T> {
  const PagedModel({
    required this.content,
    required this.number,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.firstPage,
    required this.lastPage,
  });

  factory PagedModel.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) {
    return _$PagedModelFromJson(json, fromJsonT);
  }

  @override
  @JsonKey(name: 'content')
  final List<T> content;

  @override
  @JsonKey(name: 'firstPage')
  final bool firstPage;

  @override
  @JsonKey(name: 'lastPage')
  final bool lastPage;

  @override
  @JsonKey(name: 'number')
  final int number;

  @override
  @JsonKey(name: 'size')
  final int size;

  @override
  @JsonKey(name: 'totalElements')
  final int totalElements;

  @override
  @JsonKey(name: 'totalPages')
  final int totalPages;
}
