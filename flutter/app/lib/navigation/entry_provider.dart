import 'package:console_presentation/navigation/entry_provider.dart';
import 'package:core_navigation/public.dart';
import 'package:demo_presentation/navigation/entry_provider.dart';

final class AppEntryProvider extends EntryProvider {
  AppEntryProvider() {
    include(DemoEntryProvider());
    include(ConsoleEntryProvider());
  }
}
