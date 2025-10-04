// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Data Generator
// **************************************************************************

part of 'state.dart';

@immutable
base class _ConsoleState implements ConsoleState {
  const _ConsoleState({
    this.logs = const <LogEntry>[],
    this.tags = const <String>[],
    this.selectedTags = const <String>[],
    this.searchQuery = '',
  });

  final List<
    ({AnsiColors color, String message, String tag, DateTime timestamp})
  >
  logs;

  final List<String> tags;

  final List<String> selectedTags;

  final String searchQuery;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _ConsoleState &&
            isEquals(other.logs, logs) &&
            isEquals(other.tags, tags) &&
            isEquals(other.selectedTags, selectedTags) &&
            isEquals(other.searchQuery, searchQuery);
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, logs, tags, selectedTags, searchQuery);
  }

  @override
  String toString() {
    return 'ConsoleState { logs: $logs, tags: $tags, selectedTags: $selectedTags, searchQuery: $searchQuery }';
  }
}

extension ConsoleStateGetter on ConsoleState {
  _ConsoleState get _self => this as _ConsoleState;
  List<({AnsiColors color, String message, String tag, DateTime timestamp})>
  get logs => _self.logs;
  List<String> get tags => _self.tags;
  List<String> get selectedTags => _self.selectedTags;
  String get searchQuery => _self.searchQuery;
}

extension ConsoleStateCopy on ConsoleState {
  ConsoleState copy({
    List<({AnsiColors color, String message, String tag, DateTime timestamp})>?
    logs,
    List<String>? tags,
    List<String>? selectedTags,
    String? searchQuery,
  }) {
    return _ConsoleState(
      logs: logs ?? _self.logs,
      tags: tags ?? _self.tags,
      selectedTags: selectedTags ?? _self.selectedTags,
      searchQuery: searchQuery ?? _self.searchQuery,
    );
  }
}

extension ConsoleStateApply on ConsoleState {
  ConsoleState applyLogs(
    List<({AnsiColors color, String message, String tag, DateTime timestamp})>
    logs,
  ) => copy(logs: logs);
  ConsoleState applyTags(List<String> tags) => copy(tags: tags);
  ConsoleState applySelectedTags(List<String> selectedTags) =>
      copy(selectedTags: selectedTags);
  ConsoleState applySearchQuery(String searchQuery) =>
      copy(searchQuery: searchQuery);
}
