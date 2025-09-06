// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Data Generator
// **************************************************************************

part of 'state.dart';

@immutable
base class _FirstState implements FirstState {
  const _FirstState({this.value = 0});

  final int value;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _FirstState && isEquals(other.value, value);
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, value);
  }

  @override
  String toString() {
    return 'FirstState { value: $value }';
  }
}

extension FirstStateGetter on FirstState {
  _FirstState get _self => this as _FirstState;
  int get value => _self.value;
}

extension FirstStateCopy on FirstState {
  FirstState copy({int? value}) {
    return _FirstState(value: value ?? _self.value);
  }
}

extension FirstStateApply on FirstState {
  FirstState applyValue(int value) => copy(value: value);
}
