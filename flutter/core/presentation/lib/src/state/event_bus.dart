import 'dart:async';

abstract class BaseEvent {
  const BaseEvent();
}

class EventBus {
  factory EventBus() => _instance;

  EventBus._internal();

  static final EventBus _instance = EventBus._internal();

  final Map<Type, StreamController<BaseEvent>> _bus = {};

  StreamSubscription<T> listen<T extends BaseEvent>(void Function(T event) callback) {
    final type = T;

    if (!_bus.containsKey(type)) {
      _bus[type] = StreamController<T>.broadcast();
    }

    final controller = _bus[type]! as StreamController<T>;
    return controller.stream.listen(callback);
  }

  void fire<T extends BaseEvent>(T event) {
    final type = T;

    if (_bus.containsKey(type)) {
      final controller = _bus[type]! as StreamController<T>;
      if (!controller.isClosed) {
        controller.add(event);
      }
    }
  }

  StreamSubscription<T> on<T extends BaseEvent>(void Function(T event) callback) {
    return listen<T>(callback);
  }

  void clear<T extends BaseEvent>() {
    final type = T;

    if (_bus.containsKey(type)) {
      _bus[type]!.close();
      _bus.remove(type);
    }
  }

  void clearAll() {
    for (final controller in _bus.values) {
      controller.close();
    }
    _bus.clear();
  }
}
