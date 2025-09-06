import 'package:flutter/material.dart';

final class StatefulWrapper extends StatefulWidget {
  const StatefulWrapper({
    required this.child,
    required this.initState,
    required this.dispose,
    super.key,
  });

  final Widget child;
  final void Function(BuildContext context) initState;
  final void Function(BuildContext context) dispose;

  @override
  State<StatefulWrapper> createState() => _StatefulWrapper();
}

class _StatefulWrapper extends State<StatefulWrapper> {
  @override
  void initState() {
    super.initState();
    widget.initState(context);
  }

  @override
  void dispose() {
    widget.dispose(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
