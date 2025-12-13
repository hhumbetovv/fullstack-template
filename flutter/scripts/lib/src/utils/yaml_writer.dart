class YamlWriter {
  const YamlWriter({List<String>? preferredOrder}) : _preferredOrder = preferredOrder ?? _defaultPreferredOrder;

  static const List<String> _defaultPreferredOrder = <String>[
    'name',
    'description',
    'publish_to',
    'version',
    'environment',
    'resolution',
    'workspace',
    'dependencies',
    'dev_dependencies',
    'dependency_overrides',
    'flutter',
  ];

  final List<String> _preferredOrder;

  String convert(Map<String, dynamic> input) {
    final buffer = StringBuffer();
    _writeMap(buffer, input, 0);
    return buffer.toString();
  }

  void _writeMap(StringBuffer buffer, Map<String, dynamic> map, int indent) {
    final keys = _orderedKeys(map);
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final indentation = ' ' * indent;
      buffer.write('$indentation$key:');
      if (value is Map<String, dynamic>) {
        if (value.isEmpty) {
          buffer.writeln(' {}');
        } else {
          buffer.writeln();
          _writeMap(buffer, value, indent + 2);
        }
      } else if (value is List) {
        if (value.isEmpty) {
          buffer.writeln(' []');
        } else {
          buffer.writeln();
          _writeList(buffer, value, indent + 2);
        }
      } else {
        buffer.writeln(' ${_formatScalar(value)}');
      }
    }
  }

  void _writeList(StringBuffer buffer, List<dynamic> list, int indent) {
    for (final item in list) {
      final indentation = ' ' * indent;
      if (item is Map<String, dynamic>) {
        buffer.writeln('$indentation-');
        _writeMap(buffer, item, indent + 2);
      } else if (item is List) {
        buffer.writeln('$indentation-');
        _writeList(buffer, item, indent + 2);
      } else {
        buffer.writeln('$indentation- ${_formatScalar(item)}');
      }
    }
  }

  List<String> _orderedKeys(Map<String, dynamic> map) {
    return map.keys.whereType<String>().toList()..sort((a, b) {
      final aIndex = _preferredIndex(a);
      final bIndex = _preferredIndex(b);
      if (aIndex != bIndex) {
        return aIndex.compareTo(bIndex);
      }
      return a.compareTo(b);
    });
  }

  int _preferredIndex(String key) {
    final index = _preferredOrder.indexOf(key);
    if (index == -1) {
      return _preferredOrder.length;
    }
    return index;
  }

  String _formatScalar(dynamic value) {
    if (value is String) {
      if (_needsQuoting(value)) {
        final escaped = value.replaceAll('"', r'\"');
        return '"$escaped"';
      }
      return value;
    }
    return value.toString();
  }

  bool _needsQuoting(String value) {
    if (value.isEmpty) return true;
    if (value.startsWith(' ') || value.endsWith(' ')) return true;
    if (value.contains(': ')) return true;
    if (value.contains('#')) return true;
    if (value.contains('\n')) return true;
    if (value.contains('\t')) return true;
    if (value.startsWith(RegExp(r'[\[{]'))) return true;
    if (value.contains('"')) return true;
    if (value.contains("'")) return true;
    if (value.startsWith('~')) return true;
    return false;
  }
}
