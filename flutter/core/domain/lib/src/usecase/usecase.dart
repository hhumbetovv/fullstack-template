import 'package:core_domain/src/entity/types.dart';

abstract class UseCase<Input, Output> {
  const UseCase();

  AsyncResult<Output> execute({
    required Input params,
  });
}
