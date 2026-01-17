import 'package:common_shared/public.dart';
import 'package:processor/public.dart';

part 'state.g.dart';

@data
class ConsoleState {
  const factory ConsoleState({
    @Default(<LogEntry>[]) List<LogEntry> logs,
    @Default(<String>[]) List<String> tags,
    @Default(<String>[]) List<String> selectedTags,
    @Default('') String searchQuery,
  }) = _ConsoleState;
}
