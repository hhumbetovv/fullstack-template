import 'package:processor/public.dart';

part 'paged.g.dart';

@data
class Paged<T> {
  const factory Paged({
    required List<T> content,
    required int page,
    required int size,
    required int totalElements,
    required int totalPages,
    required bool firstPage,
    required bool lastPage,
    required bool isLoading,
  }) = _Paged;

  static const empty = Paged(
    content: [],
    page: 0,
    size: 0,
    totalElements: 0,
    totalPages: 0,
    firstPage: true,
    lastPage: false,
    isLoading: false,
  );
}

extension PagedCastX<T> on Paged<T> {
  Paged<R> castAs<R>({
    List<R>? content,
    Paged<T>? copyFrom,
  }) {
    final source = copyFrom ?? this;
    final resolvedContent = content ?? source.content.whereType<R>().toList();
    return Paged(
      content: resolvedContent,
      page: source.page,
      size: source.size,
      totalElements: source.totalElements,
      totalPages: source.totalPages,
      firstPage: source.firstPage,
      lastPage: source.lastPage,
      isLoading: source.isLoading,
    );
  }
}
