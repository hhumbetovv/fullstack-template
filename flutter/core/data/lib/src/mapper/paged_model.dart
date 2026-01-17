import 'package:core_data/public.dart';
import 'package:core_domain/public.dart';

extension PagedMapper<T> on PagedModel<T> {
  Paged<R> map<R>(R Function(T) mapper) {
    final mappedPageInfo = Paged.empty.copy(
      firstPage: firstPage,
      lastPage: lastPage,
      page: page,
      size: size,
      totalElements: totalElements,
      totalPages: totalPages,
      isLoading: false,
    );

    return mappedPageInfo.castAs<R>(
      content: content?.whereType<T>().map(mapper).toList() ?? [],
    );
  }
}
