import 'package:core_domain/src/entity/failure.dart';
import 'package:core_domain/src/entity/types.dart';
import 'package:core_domain/src/result/result.dart';

abstract class PaginationUseCase<Params, Data> {
  PaginationUseCase();

  final Map<String, int> _pageTracker = {};

  PagedResult<Data> execute({
    required Params params,
    required int page,
    required int size,
  });

  PagedResult<Data> fetch({
    required String id,
    required Params params,
    required int size,
    int? page,
  }) async {
    final currentPage = page ?? getPage(id);

    final result = await execute(
      params: params,
      page: currentPage,
      size: size,
    );

    if (result.isSuccess()) {
      final entity = result.getOrThrow();
      _pageTracker[id] = currentPage + 1;
      return Success(entity);
    } else {
      return Error(result.tryGetError() ?? Failure());
    }
  }

  void resetPage() {
    _pageTracker.clear();
  }

  int getPage(String id) => _pageTracker[id] ?? 0;
}
