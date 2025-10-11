import 'package:core_domain/public.dart';

part 'error.dart';
part 'success.dart';

typedef SuccessCallback<W, S> = W Function(S success, Action? action);
typedef ErrorCallback<W, E> = W Function(E failure, Action? action);

typedef ResultOf<S, E> = Result<S, E>;

sealed class Result<S, E> {
  const Result({this.action});

  const factory Result.success(S s) = Success;

  const factory Result.error(E e) = Error;

  final Action? action;

  S getOrThrow();

  S? tryGetSuccess();

  E? tryGetError();

  bool isError();

  bool isSuccess();

  W when<W>({
    required SuccessCallback<W, S> onSuccess,
    required ErrorCallback<W, E> onError,
  });

  R? whenSuccess<R>(
    R Function(S success) whenSuccess,
  );

  R? whenError<R>(
    R Function(E error) whenError,
  );
}
