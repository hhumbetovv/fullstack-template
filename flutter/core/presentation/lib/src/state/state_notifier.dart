// NO_DOC
// ignore_for_file: strict_raw_type, prefer_asserts_with_message

import 'package:flutter/foundation.dart';

typedef StateListener<T> = ({ValueChanged<T> listener, bool Function(T previous, T next)? condition});

const String _libraryName = 'package:view_kit/core.dart';

abstract class StateNotifier<Data> {
  StateNotifier() {
    _state = initialState;
    onCreate();
  }

  void onCreate() {}

  late Data _state;

  Data get state => _state;

  Data get initialState;

  int _count = 0;

  static final List<StateListener?> _emptyListeners = List<StateListener?>.filled(0, null);
  List<StateListener<Data>?> _listeners = _emptyListeners;
  int _notificationCallStackDepth = 0;
  int _reentrantlyRemovedListeners = 0;
  bool _debugDisposed = false;

  bool _creationDispatched = false;

  static bool debugAssertNotDisposed(StateNotifier notifier) {
    assert(() {
      if (notifier._debugDisposed) {
        throw FlutterError(
          'A ${notifier.runtimeType} was used after being disposed.\n'
          'Once you have called dispose() on a ${notifier.runtimeType}, it '
          'can no longer be used.',
        );
      }
      return true;
    }());
    return true;
  }

  @protected
  bool get hasListeners => _count > 0;

  @protected
  static void maybeDispatchObjectCreation(StateNotifier object) {
    if (kFlutterMemoryAllocationsEnabled && !object._creationDispatched) {
      FlutterMemoryAllocations.instance.dispatchObjectCreated(
        library: _libraryName,
        className: '$StateNotifier',
        object: object,
      );
      object._creationDispatched = true;
    }
  }

  @mustCallSuper
  void addListener(StateListener<Data> listener) {
    assert(StateNotifier.debugAssertNotDisposed(this));

    if (kFlutterMemoryAllocationsEnabled) {
      maybeDispatchObjectCreation(this);
    }

    if (_count == _listeners.length) {
      if (_count == 0) {
        _listeners = List<StateListener<Data>?>.filled(1, null);
      } else {
        final List<StateListener<Data>?> newListeners = List<StateListener?>.filled(_listeners.length * 2, null);
        for (var i = 0; i < _count; i++) {
          newListeners[i] = _listeners[i];
        }
        _listeners = newListeners;
      }
    }
    _listeners[_count++] = listener;
  }

  void _removeAt(int index) {
    _count -= 1;
    if (_count * 2 <= _listeners.length) {
      final List<StateListener<Data>?> newListeners = List<StateListener?>.filled(_count, null);

      for (var i = 0; i < index; i++) {
        newListeners[i] = _listeners[i];
      }

      for (var i = index; i < _count; i++) {
        newListeners[i] = _listeners[i + 1];
      }

      _listeners = newListeners;
    } else {
      for (var i = index; i < _count; i++) {
        _listeners[i] = _listeners[i + 1];
      }
      _listeners[_count] = null;
    }
  }

  @mustCallSuper
  void removeListener(StateListener<Data> listener) {
    for (var i = 0; i < _count; i++) {
      final listenerAtIndex = _listeners[i];
      if (listenerAtIndex == listener) {
        if (_notificationCallStackDepth > 0) {
          _listeners[i] = null;
          _reentrantlyRemovedListeners++;
        } else {
          _removeAt(i);
        }
        break;
      }
    }
  }

  @mustCallSuper
  void dispose() {
    assert(StateNotifier.debugAssertNotDisposed(this));
    assert(
      _notificationCallStackDepth == 0,
      'The "dispose()" method on $this was called during the call to '
      '"setState()". This is likely to cause errors since it modifies '
      'the list of listeners while the list is being used.',
    );
    assert(() {
      _debugDisposed = true;
      return true;
    }());
    if (kFlutterMemoryAllocationsEnabled && _creationDispatched) {
      FlutterMemoryAllocations.instance.dispatchObjectDisposed(object: this);
    }
    _listeners = _emptyListeners;
    _count = 0;
  }

  @protected
  @visibleForTesting
  @pragma('vm:notify-debugger-on-exception')
  void setState(Data newState) {
    assert(StateNotifier.debugAssertNotDisposed(this));

    final oldState = _state;
    _state = newState;

    _notificationCallStackDepth++;

    final end = _count;
    for (var i = 0; i < end; i++) {
      try {
        if (_listeners[i]?.condition?.call(oldState, state) ?? true) {
          _listeners[i]?.listener.call(state);
        }
      } catch (exception, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'foundation library',
            context: ErrorDescription('while dispatching notifications for $runtimeType'),
            informationCollector: () => <DiagnosticsNode>[
              DiagnosticsProperty<StateNotifier>(
                'The $runtimeType sending notification was',
                this,
                style: DiagnosticsTreeStyle.errorProperty,
              ),
            ],
          ),
        );
      }
    }

    _notificationCallStackDepth--;

    if (_notificationCallStackDepth == 0 && _reentrantlyRemovedListeners > 0) {
      final newLength = _count - _reentrantlyRemovedListeners;
      if (newLength * 2 <= _listeners.length) {
        final newListeners = List<StateListener<Data>?>.filled(newLength, null);

        var newIndex = 0;
        for (var i = 0; i < _count; i++) {
          final listener = _listeners[i];
          if (listener != null) {
            newListeners[newIndex++] = listener;
          }
        }

        _listeners = newListeners;
      } else {
        for (var i = 0; i < newLength; i += 1) {
          if (_listeners[i] == null) {
            var swapIndex = i + 1;
            while (_listeners[swapIndex] == null) {
              swapIndex += 1;
            }
            _listeners[i] = _listeners[swapIndex];
            _listeners[swapIndex] = null;
          }
        }
      }

      _reentrantlyRemovedListeners = 0;
      _count = newLength;
    }
  }
}
