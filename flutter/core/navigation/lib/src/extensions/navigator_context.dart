import 'package:core_navigation/public.dart';
import 'package:core_navigation/src/navigator/view_model.dart';
import 'package:core_presentation/exports.dart';

extension NavigatorContextExtension on BuildContext {
  void buildStack(NavStackBuilder builder) {
    NavigatorIntent.buildStack(builder).dispatch(this);
  }

  void push(NavKey route) {
    buildStack((stack) {
      return [...stack, route];
    });
  }

  void replace(NavKey route) {
    buildStack((stack) {
      return [...stack..removeLast(), route];
    });
  }

  void replaceAll(List<NavKey> routes) {
    buildStack((stack) {
      return routes;
    });
  }

  void pop([Object? result]) {
    buildStack((stack) {
      return stack..removeLast();
    });
    if (result != null) {
      setResult(result);
    }
  }

  void popUntil(NavKeyPredicate predicate, [Object? result]) {
    buildStack((stack) {
      return stack.takeWhile(predicate).toList();
    });
    if (result != null) {
      setResult(result);
    }
  }
}
