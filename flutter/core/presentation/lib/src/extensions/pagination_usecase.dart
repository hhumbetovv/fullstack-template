import 'package:common_shared/public.dart';
import 'package:core_domain/public.dart';

extension PaginationUseCaseExt<Data, Params> on PaginationUseCase<Params, Data> {
  PaginationResult<Data> call(
    Params params, {
    bool isUnique = false,
    int size = 10,
  }) {
    return _callWithParams(
      params,
      isUnique: isUnique,
      size: size,
    );
  }

  PaginationResult<Data> _callWithoutLog(
    Params params, {
    required String id,
    required int page,
    int size = 10,
  }) async {
    try {
      return await fetch(
        id: id,
        params: params,
        page: page,
        size: size,
      );
    } on Exception catch (error, stackTrace) {
      final errorLog =
          '⚠️ FLOW USECASE EXCEPTION | $runtimeType\n'
          'PARAMETERS: $Params\n'
          'EXPECTED: $Data'
          'ERROR TYPE: ${error.runtimeType}\n'
          'MESSAGE: $error\n'
          'TIMESTAMP: ${DateTime.now().toIso8601String()}';

      Console.firebaseLog(errorLog);
      Console.firebaseRecordError(
        error,
        stackTrace,
        reason: 'UseCase Execution Failed',
      );
      return Error(Failure(message: error.toString()));
    }
  }

  PaginationResult<Data> _callWithLog(
    Params params, {
    required String id,
    required int page,
    int size = 10,
  }) async {
    final stopwatch = Stopwatch()..start();
    final result = await _callWithoutLog(
      params,
      id: id,
      page: page,
      size: size,
    );
    stopwatch.stop();
    final ms = stopwatch.elapsed.inMilliseconds;
    final isSuccess = result.isSuccess();
    Console.log(
      '🌀 $runtimeType | ${ms}ms\n'
          'PARAMS: $params\n'
          'PAGE: $page\n'
          'size: $size\n'
          'RESULT: ${isSuccess ? 'SUCCESS ✅' : "ERROR 🛑 => ${result.tryGetError()}"}\n',
      AnsiColors.blue,
      'UseCase',
    );

    return result;
  }

  PaginationResult<Data> _callWithParams(
    Params params, {
    bool isUnique = false,
    int size = 10,
  }) async {
    final id = isUnique ? '$params' : '';
    final page = getPage(id);
    if (!Console.isEnabled) {
      return _callWithoutLog(
        params,
        id: id,
        page: page,
        size: size,
      );
    }
    return _callWithLog(
      params,
      id: id,
      page: page,
      size: size,
    );
  }
}

extension UnitPaginationUseCaseExt<Data> on PaginationUseCase<Unit, Data> {
  PaginationResult<Data> call({
    int size = 10,
    bool isUnique = false,
  }) {
    return _callWithParams(Unit(), isUnique: isUnique, size: size);
  }
}
