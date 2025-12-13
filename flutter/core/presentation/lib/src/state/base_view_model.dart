import 'dart:async';

import 'package:common_presentation/public.dart';
import 'package:common_shared/public.dart';
import 'package:core_domain/public.dart';
import 'package:core_presentation/src/state/event_bus.dart';
import 'package:core_presentation/src/state/state_notifier.dart';
import 'package:core_presentation/src/utils/compare_and_format.dart';
import 'package:processor/public.dart';

typedef ViewMessage = ({String content, MessageType type});

abstract class BaseViewModel<UIntent, UIState, UIEffect> extends StateNotifier<UIState> {
  BaseViewModel() {
    if (UIntent != Unit) {
      _intentController.stream.listen(onIntentUpdate);
    } else {
      _intentController.close();
    }
    if (UIEffect == Unit) _effectController.close();

    observeEvents();
  }

  final bool logEvents = true;
  final bool logState = true;
  final bool logEffects = true;
  final bool logIntents = true;

  final List<StreamSubscription<BaseEvent>> _eventSubscriptions = [];

  final EventBus _eventBus = EventBus();

  @protected
  void observeEvents() {}

  @protected
  StreamSubscription<T> onEvent<T extends BaseEvent>(void Function(T event) callback) {
    final subscription = _eventBus.on<T>((event) {
      if (logEvents) {
        Console.log(
          '🔔 EVENT CAUGHT | $runtimeType\n'
              'EVENT: ${event.runtimeType}\n'
              'DATA: ${event.toString().format()}\n',
          AnsiColors.gold,
          'ViewModel',
        );
      }
      callback(event);
    });
    _eventSubscriptions.add(subscription);
    return subscription;
  }

  @protected
  void postEvent<T extends BaseEvent>(T event) {
    if (logEvents) {
      Console.log(
        '🔔 EVENT FIRED | $runtimeType\n'
            'EVENT: ${event.runtimeType}\n'
            'DATA: ${event.toString().format()}\n',
        AnsiColors.gold,
        'ViewModel',
      );
    }
    _eventBus.fire(event);
  }

  bool _isClosed = false;

  bool get isClosed => _isClosed;

  final _intentController = StreamController<UIntent>();
  final _effectController = StreamController<UIEffect>.broadcast();
  final _messageController = StreamController<ViewMessage>.broadcast();

  Stream<UIEffect> get effectStream => _effectController.stream;

  Stream<ViewMessage> get messageStream => _messageController.stream;

  @protected
  void onIntentUpdate(UIntent intent) {}

  @protected
  void postIntent(UIntent newIntent) {
    if (_intentController.isClosed) return;
    if (logIntents) {
      Console.log(
        '🎯 INTENT DISPATCH | $runtimeType\n'
            'ACTION: ${'$newIntent'.format()}\n',
        AnsiColors.green,
        'ViewModel',
      );
    }
    _intentController.add(newIntent);
  }

  @protected
  void postEffect(UIEffect newEffect) {
    if (_effectController.isClosed) return;
    if (logEffects) {
      Console.log(
        '🎯 EFFECT FIRED | $runtimeType\n'
            'ACTION: ${'$newEffect'.format()}\n',
        AnsiColors.purple,
        'ViewModel',
      );
    }
    _effectController.add(newEffect);
  }

  @protected
  void postMessage(String message, [MessageType type = MessageType.error]) {
    if (_messageController.isClosed) return;
    _messageController.add((content: message, type: type));
  }

  @override
  void dispose() {
    super.dispose();
    _intentController.close();
    _effectController.close();
    _messageController.close();

    for (final subscription in _eventSubscriptions) {
      subscription.cancel();
    }
    _eventSubscriptions.clear();

    _isClosed = true;
  }

  @override
  void setState(UIState newState) {
    if (UIState == Unit || isClosed) return;
    if (logState) {
      Console.log(
        '🔄 STATE UPDATE | $runtimeType\n'
            'CHANGED: ${compareAndFormat(state, newState)}\n',
        AnsiColors.teal,
        'ViewModel',
      );
    }
    super.setState(newState);
  }

  Future<void> runWithLoading(FutureOr<void> Function() callback) async {
    if (state is LoadableState) {
      setState((state as LoadableState).copyLoading(true) as UIState);
      await callback();
      setState((state as LoadableState).copyLoading(false) as UIState);
    } else {
      await callback();
    }
  }
}
