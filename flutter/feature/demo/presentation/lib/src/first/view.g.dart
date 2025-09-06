// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// View Generator
// **************************************************************************

part of 'view.dart';

// ignore_for_file: unreachable_switch_case
abstract class _FirstView extends StatelessWidget implements BaseView {
  const _FirstView({super.key});

  FirstViewModel viewModelFactory(BuildContext context) {
    return FirstViewModel();
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
      child: ViewModelProvider<FirstViewModel, FirstEffect>(
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
