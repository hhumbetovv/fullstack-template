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
    List<R> content = const [],
    Paged<T>? copyFrom,
  }) {
    return Paged(
      content: content,
      page: copyFrom?.page ?? page,
      size: copyFrom?.size ?? size,
      totalElements: copyFrom?.totalElements ?? totalElements,
      totalPages: copyFrom?.totalPages ?? totalPages,
      firstPage: copyFrom?.firstPage ?? firstPage,
      lastPage: copyFrom?.lastPage ?? lastPage,
      isLoading: copyFrom?.isLoading ?? isLoading,
    );
  }
}
