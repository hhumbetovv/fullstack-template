import 'package:core_domain/src/entity/types.dart';

abstract class FlowUseCase<Input, Output> {
  const FlowUseCase();

  FlowResult<Output> execute({
    required Input params,
  });
}
