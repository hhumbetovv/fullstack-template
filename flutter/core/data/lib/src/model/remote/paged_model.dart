import 'package:json_annotation/json_annotation.dart';

part 'paged_model.g.dart';

@JsonSerializable(genericArgumentFactories: true, createToJson: false)
class PagedModel<T> {
  const PagedModel({
    required this.content,
    required this.page,
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

  @JsonKey(name: 'content')
  final List<T?>? content;

  @JsonKey(name: 'firstPage')
  final bool? firstPage;

  @JsonKey(name: 'lastPage')
  final bool? lastPage;

  @JsonKey(name: 'page')
  final int? page;

  @JsonKey(name: 'size')
  final int? size;

  @JsonKey(name: 'totalElements')
  final int? totalElements;

  @JsonKey(name: 'totalPages')
  final int? totalPages;
}
