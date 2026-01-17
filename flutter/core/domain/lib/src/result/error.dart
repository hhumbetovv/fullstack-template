// NO_DOC
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

part of 'result.dart';

final class Error<S, E> extends Result<S, E> {
  const Error(this._error, {super.action});

  static Error<S, Unit> unit<S>({Action? action}) {
    return Error<S, Unit>(Unit(), action: action);
  }

  final E _error;

  E get error => _error;

  @override
  bool isError() => true;

  @override
  bool isSuccess() => false;

  @override
  int get hashCode => _error.hashCode;

  @override
  bool operator ==(Object other) => other is Error && other._error == _error;

  @override
  W when<W>({
    required SuccessCallback<W, S> onSuccess,
    required ErrorCallback<W, E> onError,
  }) {
    return onError(_error, action);
  }

  @override
  // NO_DOC
  // ignore: inference_failure_on_instance_creation
  S getOrThrow() => throw const SuccessResultNotFoundException();

  @override
  E tryGetError() => _error;

  @override
  S? tryGetSuccess() => null;

  @override
  R whenError<R>(R Function(E error) whenError) => whenError(_error);

  @override
  R? whenSuccess<R>(R Function(S success) whenSuccess) => null;

  @override
  String toString() {
    return 'Error { $_error }';
  }
}

final class SuccessResultNotFoundException<S, E> implements Exception {
  const SuccessResultNotFoundException();

  @override
  String toString() {
    return '''
      Tried to get the success value of [$S], but none was found. 
      Make sure you're checking for `isSuccess` before trying to get it through
      `getOrThrow`. You can also use `tryGetSuccess` if you're unsure or 
      `if (result case Success())`
    ''';
  }
}
