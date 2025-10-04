// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// View Generator
// **************************************************************************

part of 'view.dart';

// ignore_for_file: unreachable_switch_case
abstract class _ConsoleView extends StatelessWidget implements BaseView {
  const _ConsoleView({super.key});

  ConsoleViewModel viewModelFactory(BuildContext context) {
    return ConsoleViewModel();
  }

  @override
  void initState(BuildContext context) {}
  @override
  void dispose(BuildContext context) {}
  Widget builder({required BuildContext context, required Widget child}) {
    return child;
  }

  Widget buildView(BuildContext context);
  @override
  Widget build(BuildContext context) {
    return builder(
      context: context,
      child: ViewModelProvider<ConsoleViewModel, ConsoleEffect>(
        create: viewModelFactory,
        child: Builder(
          builder: (ctx) {
            return buildView(ctx);
          },
        ),
      ),
    );
  }
}
