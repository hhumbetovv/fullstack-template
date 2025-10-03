import 'package:flutter/widgets.dart';

abstract class ScrollPaginationWidget extends StatefulWidget {
  const ScrollPaginationWidget({
    required this.canFetch,
    required this.fetch,
    super.key,
    this.controller,
  });

  final bool canFetch;
  final VoidCallback fetch;
  final ScrollController? controller;

  @override
  ScrollPaginationState<ScrollPaginationWidget> createState();
}

abstract class ScrollPaginationState<T extends ScrollPaginationWidget> extends State<T> {
  late final controller = widget.controller ?? ScrollController();

  void _fetch() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange &&
        widget.canFetch) {
      widget.fetch();
    }
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(_fetch);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkInitialFill());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkInitialFill());
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkInitialFill());
  }

  void _checkInitialFill() {
    if (!widget.canFetch) return;

    if (controller.position.maxScrollExtent == 0) {
      widget.fetch();
    }
  }

  @override
  void dispose() {
    super.dispose();
    controller.removeListener(_fetch);
    if (widget.controller == null) {
      controller.dispose();
    }
  }

  Widget buildView(BuildContext context, ScrollController controller);

  @override
  Widget build(BuildContext context) {
    return buildView(context, controller);
  }
}
