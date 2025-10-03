import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ui_components/public.dart';

class Collapsible extends StatefulWidget {
  const Collapsible({
    required this.header,
    required this.child,
    super.key,
    this.appBar,
    this.bottomAppBar,
  });

  final Widget? appBar;
  final Widget? bottomAppBar;
  final Widget header;
  final Widget child;

  @override
  State<Collapsible> createState() => _CollapsibleState();
}

class _CollapsibleState extends State<Collapsible> {
  double? initialHeight;
  double height = 0;

  @override
  void didUpdateWidget(covariant Collapsible oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.header != oldWidget.header) {
      initialHeight = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (initialHeight == null) {
      return OverflowBox(
        maxWidth: double.maxFinite,
        child: UnconstrainedBox(
          child: MeasureSize(
            onChange: (size) {
              setState(() {
                initialHeight = size.height;
                height = size.height;
              });
            },
            child: SizedBox(
              width: double.maxFinite,
              child: widget.header,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        ?widget.appBar,
        ClipRect(
          child: SizedBox(
            height: height,
            width: double.maxFinite,
            child: OverflowBox(
              minHeight: 0,
              maxHeight: double.maxFinite,
              alignment: Alignment.bottomCenter,
              child: MeasureSize(
                onChange: (size) {
                  if (initialHeight != null && (size.height - initialHeight!).abs() > 1.0) {
                    setState(() {
                      final oldInitialHeight = initialHeight;
                      initialHeight = size.height;
                      if (height == oldInitialHeight) {
                        height = size.height;
                      } else {
                        final ratio = oldInitialHeight! > 0 ? height / oldInitialHeight : 0;
                        height = (size.height * ratio).clamp(0.0, size.height);
                      }
                    });
                  }
                  if (initialHeight == 0 && size.height != 0) {
                    setState(() {
                      initialHeight = null;
                    });
                  }
                },
                child: Opacity(
                  opacity: (height / (initialHeight ?? 0)).clamp(0, 1),
                  child: widget.header,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: ScrollConfiguration(
            behavior: height == initialHeight || height == 0 ? ScrollConfiguration.of(context) : _NoScrollBehavior(),
            child: _ScrollGestureInterceptor(
              onUpdate: (delta) {
                setState(() {
                  height = (height + (delta ?? 0)).clamp(0.0, initialHeight ?? 0);
                });
              },
              child: RepaintBoundary(
                child: widget.child,
              ),
            ),
          ),
        ),
        ?widget.bottomAppBar,
      ],
    );
  }
}

class _ScrollGestureInterceptor extends StatelessWidget {
  const _ScrollGestureInterceptor({
    required this.child,
    required this.onUpdate,
  });

  final Widget child;
  final void Function(double? delta) onUpdate;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        _SmartVerticalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<_SmartVerticalDragGestureRecognizer>(
          _SmartVerticalDragGestureRecognizer.new,
          (instance) {
            instance.onUpdate = (details) {
              onUpdate(details.primaryDelta);
            };
          },
        ),
      },
      child: child,
    );
  }
}

class _SmartVerticalDragGestureRecognizer extends VerticalDragGestureRecognizer {
  static const double _directionalThreshold = 2;
  Offset? _initialPoint;
  bool _isHorizontalDrag = false;

  @override
  void addPointer(PointerDownEvent event) {
    _initialPoint = event.position;
    _isHorizontalDrag = false;
    super.addPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent && _initialPoint != null) {
      final dx = (event.position.dx - _initialPoint!.dx).abs();
      final dy = (event.position.dy - _initialPoint!.dy).abs();

      if (dx > dy * _directionalThreshold) {
        _isHorizontalDrag = true;
      }
    }
    super.handleEvent(event);
  }

  @override
  void rejectGesture(int pointer) {
    if (!_isHorizontalDrag) {
      acceptGesture(pointer);
    } else {
      super.rejectGesture(pointer);
    }
  }
}

class _NoScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const _BlockScrollPhysics();
  }
}

class _BlockScrollPhysics extends ScrollPhysics {
  const _BlockScrollPhysics({super.parent});

  @override
  _BlockScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _BlockScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return 0;
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => true;
}
