import 'package:flutter/material.dart';

enum Swipe { up, down, left, right }

class KonamiSwipeDetector extends StatefulWidget {
  const KonamiSwipeDetector({
    required this.child,
    required this.onDetect,
    super.key,
  });
  final Widget child;
  final VoidCallback onDetect;

  @override
  State<KonamiSwipeDetector> createState() => _KonamiSwipeDetectorState();
}

class _KonamiSwipeDetectorState extends State<KonamiSwipeDetector> {
  final List<Swipe> _input = [];

  final List<Swipe> _konamiCode = [
    Swipe.up,
    Swipe.down,
    Swipe.left,
    Swipe.right,
  ];

  Offset? _startPosition;

  static const double swipeThreshold = 50;

  void _handleSwipe(Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;

    if (dx.abs() > dy.abs()) {
      if (dx > swipeThreshold) {
        _registerInput(Swipe.right);
      } else if (dx < -swipeThreshold) {
        _registerInput(Swipe.left);
      }
    } else {
      if (dy > swipeThreshold) {
        _registerInput(Swipe.down);
      } else if (dy < -swipeThreshold) {
        _registerInput(Swipe.up);
      }
    }
  }

  void _registerInput(Swipe direction) {
    _input.add(direction);
    if (_input.length > _konamiCode.length) {
      _input.removeAt(0);
    }
    if (_input.length < _konamiCode.length) return;

    var isMatch = true;
    for (var i = 0; i < _konamiCode.length; i++) {
      if (_input[i] != _konamiCode[i]) {
        isMatch = false;
        break;
      }
    }

    if (_input.length == _konamiCode.length && isMatch) {
      widget.onDetect();
      _input.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        _startPosition = event.position;
      },
      onPointerUp: (event) {
        if (_startPosition != null) {
          _handleSwipe(_startPosition!, event.position);
        }
      },
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
