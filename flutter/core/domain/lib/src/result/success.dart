// NO_DOC
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

part of 'result.dart';

final class Success<S, E> extends Result<S, E> {
  const Success(this._success, {super.action});

  static Success<Unit, E> unit<E>({Action? action}) {
    return Success<Unit, E>(Unit(), action: action);
  }

  final S _success;

  @override
  bool isError() => false;

  @override
  bool isSuccess() => true;

  @override
  int get hashCode => _success.hashCode;

  @override
  bool operator ==(Object other) {
    return other is Success && other._success == _success;
  }

  S get success => _success;

  @override
  S getOrThrow() => _success;

  @override
  E? tryGetError() => null;

  @override
  S tryGetSuccess() => _success;

  @override
  R? whenError<R>(R Function(E error) whenError) => null;

  @override
  R whenSuccess<R>(R Function(S success) whenSuccess) {
    return whenSuccess(_success);
  }

  @override
  W when<W>({required SuccessCallback<W, S> onSuccess, required ErrorCallback<W, E> onError}) {
    return onSuccess(_success, action);
  }

  @override
  String toString() {
    return 'Success { $_success }';
  }
}
