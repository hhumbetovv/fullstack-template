import 'package:console_presentation/navigation/nav_keys.dart';
import 'package:console_presentation/src/console/view.dart';
import 'package:core_navigation/public.dart';

final class ConsoleEntryProvider extends EntryProvider {
  ConsoleEntryProvider() {
    entry<ConsoleNavKey>(
      builder: (key) {
        return const ConsoleView();
      },
    );
  }
}
