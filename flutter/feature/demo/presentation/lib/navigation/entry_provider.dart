import 'package:core_navigation/public.dart';
import 'package:demo_presentation/navigation/nav_keys.dart';
import 'package:demo_presentation/src/first/view.dart';

class DemoEntryProvider extends EntryProvider {
  DemoEntryProvider() {
    entry<FirstNavKey>(
      builder: (key) {
        return const FirstView();
      },
    );
  }
}
