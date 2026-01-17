import 'package:flutter/foundation.dart';

extension LogFormatter on String {
  String format() {
    if (kReleaseMode || trim().isEmpty) return this;

    final trimmed = trim();

    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      return _formatGenericList(this);
    }

    if (_isGenericEntityFormat(trimmed)) {
      return _formatGenericEntity(trimmed);
    }

    return this;
  }

  String _formatGenericEntity(String entityStr) {
    final openBraceIndex = entityStr.indexOf('{');
    if (openBraceIndex == -1) return entityStr;

    final closeBraceIndex = _findMatchingBracket(entityStr, openBraceIndex);
    if (closeBraceIndex == -1) return entityStr;

    final entityName = entityStr.substring(0, openBraceIndex).trim();
    final entityContent = entityStr.substring(openBraceIndex + 1, closeBraceIndex).trim();

    final fields = _parseEntityFields(entityContent);

    final buffer = StringBuffer('$entityName {\n');

    fields.forEach((key, value) {
      if (_isGenericEntityFormat(value)) {
        final formattedValue = _formatGenericEntity(value);
        final lines = formattedValue.split('\n');

        buffer.write('  $key: ${lines[0]}\n');
        for (var i = 1; i < lines.length; i++) {
          buffer.write('  ${lines[i]}\n');
        }
      } else if (value.trim().startsWith('[') && value.trim().endsWith(']')) {
        final formattedList = _formatGenericList(value);
        final lines = formattedList.split('\n');

        buffer.write('  $key: ${lines[0]}\n');
        for (var i = 1; i < lines.length; i++) {
          buffer.write('  ${lines[i]}\n');
        }
      } else {
        buffer.write('  $key: $value,\n');
      }
    });

    buffer.write('}');
    return buffer.toString();
  }

  String _formatGenericList(String listStr) {
    final trimmed = listStr.trim();
    if (trimmed == '[]') return '[]';

    final content = trimmed.substring(1, trimmed.length - 1).trim();
    if (content.isEmpty) return '[]';

    final items = _splitListItems(content);

    final buffer = StringBuffer('[\n');

    for (var i = 0; i < items.length; i++) {
      final item = items[i].trim();

      if (_isGenericEntityFormat(item)) {
        final formattedEntity = _formatGenericEntity(item);
        final lines = formattedEntity.split('\n');

        for (var j = 0; j < lines.length; j++) {
          buffer.write('  ${lines[j]}');
          if (j < lines.length - 1) buffer.write('\n');
        }
      } else {
        buffer.write('  $item');
      }

      if (i < items.length - 1) buffer.write(',');
      buffer.write('\n');
    }

    buffer.write(']');
    return buffer.toString();
  }

  bool _isGenericEntityFormat(String text) {
    final trimmed = text.trim();

    return RegExp(r'^\w+\s*\{.*\}$', dotAll: true).hasMatch(trimmed);
  }

  Map<String, String> _parseEntityFields(String content) {
    final fields = <String, String>{};

    var position = 0;
    while (position < content.length) {
      final colonIndex = content.indexOf(':', position);
      if (colonIndex == -1) break;

      final fieldName = content.substring(position, colonIndex).trim();

      var valueStart = colonIndex + 1;
      while (valueStart < content.length && content[valueStart] == ' ') {
        valueStart++;
      }

      int valueEnd;

      if (valueStart < content.length) {
        if (valueStart < content.length && content[valueStart] == '{') {
          valueEnd = _findMatchingBracket(content, valueStart);
          if (valueEnd == -1) valueEnd = content.length;

          var tempEnd = valueEnd + 1;
          while (tempEnd < content.length && content[tempEnd] != ',' && content[tempEnd] != '}') {
            tempEnd++;
          }
          valueEnd = tempEnd;
        } else if (valueStart < content.length && content[valueStart] == '[') {
          valueEnd = _findMatchingSquareBracket(content, valueStart);
          if (valueEnd == -1) valueEnd = content.length;

          var tempEnd = valueEnd + 1;
          while (tempEnd < content.length && content[tempEnd] != ',' && content[tempEnd] != '}') {
            tempEnd++;
          }
          valueEnd = tempEnd;
        } else {
          var entityNameEnd = valueStart;
          while (entityNameEnd < content.length && RegExp('[a-zA-Z0-9_]').hasMatch(content[entityNameEnd])) {
            entityNameEnd++;
          }

          var tempPos = entityNameEnd;
          while (tempPos < content.length && content[tempPos] == ' ') {
            tempPos++;
          }

          if (tempPos < content.length && content[tempPos] == '{') {
            valueEnd = _findMatchingBracket(content, tempPos);
            if (valueEnd == -1) valueEnd = content.length;

            var tempEnd = valueEnd + 1;
            while (tempEnd < content.length && content[tempEnd] != ',' && content[tempEnd] != '}') {
              tempEnd++;
            }
            valueEnd = tempEnd;
          } else {
            valueEnd = content.indexOf(',', valueStart);
            if (valueEnd == -1) {
              valueEnd = content.indexOf('}', valueStart);
              if (valueEnd == -1) {
                valueEnd = content.length;
              }
            }
          }
        }
      } else {
        valueEnd = content.length;
      }

      if (valueStart > content.length) valueStart = content.length;
      if (valueEnd > content.length) valueEnd = content.length;
      if (valueEnd < valueStart) valueEnd = valueStart;

      var fieldValue = content.substring(valueStart, valueEnd).trim();
      if (fieldValue.endsWith(',')) {
        fieldValue = fieldValue.substring(0, fieldValue.length - 1).trim();
      }

      fields[fieldName] = fieldValue;

      position = valueEnd + 1;
      while (position < content.length && (content[position] == ' ' || content[position] == ',')) {
        position++;
      }
    }

    return fields;
  }

  List<String> _splitListItems(String content) {
    final items = <String>[];

    var index = 0;
    var startIndex = 0;
    var inEntity = false;
    var inList = false;
    var entityDepth = 0;
    var listDepth = 0;

    while (index < content.length) {
      final char = content[index];

      if (char == '{') {
        inEntity = true;
        entityDepth++;
      } else if (char == '}') {
        entityDepth--;
        if (entityDepth == 0) inEntity = false;
      } else if (char == '[') {
        inList = true;
        listDepth++;
      } else if (char == ']') {
        listDepth--;
        if (listDepth == 0) inList = false;
      } else if (char == ',' && !inEntity && !inList) {
        items.add(content.substring(startIndex, index).trim());
        startIndex = index + 1;
      }

      index++;
    }

    if (startIndex < content.length) {
      items.add(content.substring(startIndex).trim());
    }

    return items;
  }

  int _findMatchingBracket(String text, int openBraceIndex) {
    if (openBraceIndex < 0 || openBraceIndex >= text.length || text[openBraceIndex] != '{') {
      return -1;
    }

    var depth = 1;
    for (var i = openBraceIndex + 1; i < text.length; i++) {
      if (text[i] == '{') {
        depth++;
      } else if (text[i] == '}') {
        depth--;
        if (depth == 0) {
          return i;
        }
      }
    }

    return -1;
  }

  int _findMatchingSquareBracket(String text, int openBracketIndex) {
    if (openBracketIndex < 0 || openBracketIndex >= text.length || text[openBracketIndex] != '[') {
      return -1;
    }

    var depth = 1;
    for (var i = openBracketIndex + 1; i < text.length; i++) {
      if (text[i] == '[') {
        depth++;
      } else if (text[i] == ']') {
        depth--;
        if (depth == 0) {
          return i;
        }
      }
    }

    return -1;
  }
}
