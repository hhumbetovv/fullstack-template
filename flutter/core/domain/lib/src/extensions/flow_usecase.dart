import 'dart:async';

import 'package:common_shared/public.dart';
import 'package:core_domain/public.dart';

extension FlowUseCaseExt<Data, Params> on FlowUseCase<Params, Data> {
  FlowResult<Data> call(Params params) => _callWithParams(params);

  FlowResult<Data> _callWithoutLog(
    Params params,
  ) async {
    try {
      return await execute(params: params);
    } on Object catch (error, stackTrace) {
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

      return Stream.value(Error(Failure(message: error.toString())));
    }
  }

  FlowResult<Data> _callWithLog(
    Params params,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final resultStream = await execute(params: params);

      stopwatch.stop();
      final ms = stopwatch.elapsed.inMilliseconds;
      Console.log(
        '🌊 $runtimeType\n'
            'PARAMS: $params\n'
            'INITIALIZED ✅: ${ms}ms\n',
        AnsiColors.blue,
        'UseCase',
      );
      return resultStream.map((result) {
        if (result.isSuccess()) {
          Console.log(
            '🌊 $runtimeType\n'
                'EMITTED SUCCESS ✅\n',
            AnsiColors.blue,
            'UseCase',
          );
        } else {
          Console.log(
            '🌊 $runtimeType\n'
                'EMITTED ERROR 🛑 => ${result.tryGetError()}\n',
            AnsiColors.blue,
            'UseCase',
          );
        }
        return result;
      });
    } on Object catch (e) {
      stopwatch.stop();
      final ms = stopwatch.elapsed.inMilliseconds;
      Console.log(
        '🌊 $runtimeType | ${ms}ms\n'
            'PARAMS: $params\n'
            "CAN'T INITIALIZE 🛑: $e\n",
        AnsiColors.blue,
        'UseCase',
      );
      return Stream.value(Error(Failure(message: e.toString())));
    }
  }

  FlowResult<Data> _callWithParams(
    Params params,
  ) async {
    if (!Console.isEnabled) return _callWithoutLog(params);
    return _callWithLog(params);
  }
}

extension UnitFlowUseCaseExt<Data> on FlowUseCase<Unit, Data> {
  FlowResult<Data> call() => _callWithParams(Unit());
}
