import 'dart:io';

import 'package:common_shared/public.dart';
import 'package:core_presentation/exports.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:processor/public.dart';
import 'package:share_plus/share_plus.dart';

import 'state.dart';

export 'state.dart';

part 'view_model.g.dart';

@viewModel
final class ConsoleViewModel extends _ConsoleViewModel {
  @override
  ConsoleState get initialState {
    return ConsoleState(
      tags: Console.tags,
      logs: Console.history,
    );
  }

  final debounce = Debounce(milliseconds: 750);

  @override
  bool get logEffects => false;

  @override
  bool get logEvents => false;

  @override
  bool get logIntents => false;

  @override
  bool get logState => false;

  @intent
  void _refresh() {
    final tags = Console.tags;

    final selectedTags = state.selectedTags.where(tags.contains).toList();
    final logs = Console.history.where((log) {
      final containsTag = selectedTags.isEmpty || selectedTags.contains(log.tag);
      final containsQuery = log.message.toLowerCase().contains(state.searchQuery);
      return containsTag && containsQuery;
    }).toList();

    setState(
      state.copy(
        tags: tags,
        selectedTags: selectedTags,
        logs: logs,
      ),
    );
  }

  @intent
  void _toggleTag(String value) {
    setState(state.applySelectedTags(state.selectedTags.toggle(value)));
    _refresh();
  }

  @intent
  void _setQuery(String value) {
    debounce(() {
      setState(state.applySearchQuery(value.toLowerCase()));
      _refresh();
    });
  }

  @intent
  Future<void> _shareLogs() async {
    final logsTxt = Console.exportLogsAsStrings().join('\n');
    if (logsTxt.isEmpty) {
      postMessage('There is no log', MessageType.info);
      return;
    }
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/app_logs_${DateTime.now().millisecondsSinceEpoch}.txt');

      await file.writeAsString(logsTxt);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)]),
      );
    } on Object catch (e) {
      postMessage('Failed to share logs: $e');
    }
  }

  @intent
  void _copyLogs() {
    final logsTxt = Console.exportLogsAsStrings().join('\n');
    if (logsTxt.isEmpty) {
      postMessage('There is no log', MessageType.info);
    } else {
      Clipboard.setData(ClipboardData(text: logsTxt));
      postMessage('Logs copied to clipboard', MessageType.success);
    }
  }

  @intent
  void _clearLogs() {
    Console.clearLogs();
    _refresh();
  }
}

extension<T> on List<T> {
  List<T> toggle(T value) {
    final hasValue = contains(value);
    if (hasValue) {
      return [...this]..remove(value);
    }
    return [...this, value];
  }
}
