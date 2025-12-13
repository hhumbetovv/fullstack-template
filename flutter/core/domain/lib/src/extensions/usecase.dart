import 'package:common_shared/public.dart';
import 'package:core_domain/public.dart';

extension UseCaseExt<Data, Params> on UseCase<Params, Data> {
  AsyncResult<Data> call(Params params) => _callWithParams(params);

  AsyncResult<Data> _callWithoutLog(
    Params params,
  ) async {
    try {
      return await execute(params: params);
    } on Object catch (error, stackTrace) {
      final errorLog =
          '⚠️ USECASE EXCEPTION | $runtimeType\n'
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

  AsyncResult<Data> _callWithLog(
    Params params,
  ) async {
    final stopwatch = Stopwatch()..start();
    final result = await _callWithoutLog(params);
    stopwatch.stop();
    final ms = stopwatch.elapsed.inMilliseconds;
    final isSuccess = result.isSuccess();
    Console.log(
      '🧩 $runtimeType | ${ms}ms\n'
          'PARAMS: $params\n'
          'RESULT: ${isSuccess ? 'SUCCESS ✅' : "ERROR 🛑 => ${result.tryGetError()}"}\n',
      AnsiColors.blue,
      'UseCase',
    );

    return result;
  }

  AsyncResult<Data> _callWithParams(
    Params params,
  ) async {
    if (!Console.isEnabled) return _callWithoutLog(params);
    return _callWithLog(params);
  }
}

extension UnitUseCaseExt<Data> on UseCase<Unit, Data> {
  AsyncResult<Data> call() async {
    return _callWithParams(Unit());
  }
}
