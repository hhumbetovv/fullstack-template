import 'package:core_navigation/public.dart';
import 'package:core_presentation/exports.dart';
import 'package:demo_presentation/navigation/nav_keys.dart';

final class AppProviderScope extends MultiProvider {
  AppProviderScope({
    required super.child,
    super.key,
  }) : super(
         providers: [
           const NavigatorProvider(
             stack: [
               FirstNavKey(),
             ],
           ),
         ],
       );
}
