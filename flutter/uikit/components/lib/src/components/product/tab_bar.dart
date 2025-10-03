import 'package:flutter/material.dart';
import 'package:ui_components/public.dart';
import 'package:ui_foundation/public.dart';

class UiTabItem {
  const UiTabItem({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;
}

class UiTabBar extends StatefulWidget {
  const UiTabBar({
    required this.items,
    this.controller,
    super.key,
    this.indicatorHeight = AppDefaults.buttonHeight,
    this.onIndexChanged,
  }) : assert(items.length > 0, 'UiTabBar requires at least one item.');

  final List<UiTabItem> items;
  final TabController? controller;
  final double indicatorHeight;
  final ValueChanged<int>? onIndexChanged;

  @override
  State<UiTabBar> createState() => _UiTabBarState();
}

class _UiTabBarState extends State<UiTabBar> with SingleTickerProviderStateMixin {
  TabController? _internalController;
  TabController? _attachedController;
  int? _lastReportedIndex;

  TabController get _controller => widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    _syncController();
  }

  @override
  void didUpdateWidget(covariant UiTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final itemsChanged = oldWidget.items.length != widget.items.length;

    if (widget.controller != oldWidget.controller || itemsChanged) {
      if (oldWidget.controller == null) {
        _internalController?.dispose();
      }
      _syncController();
    }

    if (widget.controller != null) {
      assert(
        widget.controller!.length == widget.items.length,
        'UiTabBar controller length (${widget.controller!.length}) must match '
        'items length (${widget.items.length}).',
      );
    }
  }

  @override
  void dispose() {
    _detachListener();
    _internalController?.dispose();
    super.dispose();
  }

  void _syncController() {
    if (widget.controller != null) {
      assert(
        widget.controller!.length == widget.items.length,
        'UiTabBar controller length (${widget.controller!.length}) must match '
        'items length (${widget.items.length}).',
      );
      _attachListener(widget.controller!);
      _internalController = null;
      return;
    }

    final previousIndex = _internalController?.index ?? 0;
    if (_internalController != null) {
      if (_attachedController == _internalController) {
        _detachListener();
      }
      _internalController?.dispose();
    }
    final initialIndex = previousIndex.clamp(0, widget.items.length - 1);
    _internalController = TabController(
      length: widget.items.length,
      vsync: this,
      initialIndex: (initialIndex as num).toInt(),
    );
    _attachListener(_internalController!);
  }

  void _attachListener(TabController controller) {
    if (_attachedController == controller) {
      _lastReportedIndex = controller.index;
      return;
    }
    _detachListener();
    _attachedController = controller;
    _lastReportedIndex = controller.index;
    controller.addListener(_handleControllerTick);
  }

  void _detachListener() {
    _attachedController?.removeListener(_handleControllerTick);
    _attachedController = null;
    _lastReportedIndex = null;
  }

  void _handleControllerTick() {
    final controller = _attachedController;
    if (controller == null) {
      return;
    }
    if (controller.indexIsChanging) {
      return;
    }
    final currentIndex = controller.index;
    if (_lastReportedIndex == currentIndex) {
      return;
    }
    _lastReportedIndex = currentIndex;
    widget.onIndexChanged?.call(currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final tabPalette = context.palette.tab;
    final controller = _controller;
    final tabs = widget.items
        .map((item) {
          return Tab(text: item.label);
        })
        .toList(growable: false);
    return Collapsible(
      header: Stack(
        children: [
          IgnorePointer(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: widget.indicatorHeight,
              ),
              child: SizedBox(
                height: double.minPositive,
                child: TabBar(
                  controller: controller,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: EdgeInsets.zero,
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(
                      color: tabPalette.selected,
                      width: widget.indicatorHeight,
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  labelPadding: EdgeInsets.zero,
                  dividerColor: Colors.transparent,
                  isScrollable: false,
                  labelColor: Colors.transparent,
                  unselectedLabelColor: Colors.transparent,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  splashFactory: NoSplash.splashFactory,
                  tabs: tabs,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: controller.animation ?? controller,
              builder: (context, _) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < widget.items.length; index++)
                      Expanded(
                        child: Clickable(
                          semanticId: widget.items[index].label,
                          onTap: () {
                            if (controller.index == index && !controller.indexIsChanging) {
                              return;
                            }
                            controller.animateTo(index);
                          },
                          child: Padding(
                            padding: const AppPadding.mediumV(),
                            child: Center(
                              child: _TabLabel(
                                palette: tabPalette,
                                controller: controller,
                                index: index,
                                text: widget.items[index].label,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      child: TabBarView(
        controller: controller,
        children: [
          for (final item in widget.items) item.child,
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.palette,
    required this.controller,
    required this.index,
    required this.text,
  });

  final TabPalette palette;
  final TabController controller;
  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final animationValue = controller.animation?.value ?? controller.index.toDouble();
    final distance = (animationValue - index).abs().clamp(0.0, 1.0);
    final t = (1 - distance).clamp(0.0, 1.0);
    final color = Color.lerp(palette.idle, palette.selected, t) ?? palette.selected;

    return UiText(
      text,
      textAlign: TextAlign.center,
      color: color,
    );
  }
}
