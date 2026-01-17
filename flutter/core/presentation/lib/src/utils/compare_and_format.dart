import 'package:common_presentation/public.dart';

String compareAndFormat<T>(T oldObject, T newObject) {
  if (oldObject.runtimeType != newObject.runtimeType) {
    return 'Objects are of different types: ${oldObject.runtimeType} vs ${newObject.runtimeType}';
  }

  final oldString = oldObject.toString();
  final newString = newObject.toString();

  final className = _extractClassName(oldString);
  final oldFields = _extractFields(oldString);
  final newFields = _extractFields(newString);

  final diffMap = <String, dynamic>{};

  oldFields.forEach((key, oldValue) {
    if (newFields.containsKey(key)) {
      final newValue = newFields[key]!;

      if (oldValue != newValue) {
        if (_isNestedObject(oldValue) && _isNestedObject(newValue)) {
          final nestedOldClassName = _extractClassName(oldValue);
          final nestedOldFields = _extractFields(oldValue);
          final nestedNewFields = _extractFields(newValue);

          final nestedDiffMap = <String, dynamic>{};
          var hasNestedChanges = false;

          nestedOldFields.forEach((nestedKey, nestedOldValue) {
            if (nestedNewFields.containsKey(nestedKey)) {
              final nestedNewValue = nestedNewFields[nestedKey]!;

              if (nestedOldValue != nestedNewValue) {
                if (_isNestedObject(nestedOldValue) && _isNestedObject(nestedNewValue)) {
                  final deepDiff = compareAndFormat(
                    _createDummyObject(nestedOldValue),
                    _createDummyObject(nestedNewValue),
                  );

                  if (deepDiff != 'No differences found') {
                    nestedDiffMap[nestedKey] = deepDiff;
                    hasNestedChanges = true;
                  }
                } else {
                  nestedDiffMap[nestedKey] = nestedNewValue;
                  hasNestedChanges = true;
                }
              }
            }
          });

          nestedNewFields.forEach((nestedKey, nestedNewValue) {
            if (!nestedOldFields.containsKey(nestedKey)) {
              nestedDiffMap[nestedKey] = nestedNewValue;
              hasNestedChanges = true;
            }
          });

          if (hasNestedChanges) {
            var nestedDiffString = '$nestedOldClassName {';
            nestedDiffMap.forEach((nestedKey, nestedValue) {
              nestedDiffString += ' $nestedKey: $nestedValue,';
            });

            if (nestedDiffString.endsWith(',')) {
              nestedDiffString = nestedDiffString.substring(0, nestedDiffString.length - 1);
            }
            nestedDiffString += ' }';

            diffMap[key] = nestedDiffString;
          }
        } else if (_isNestedList(oldValue) && _isNestedList(newValue)) {
          diffMap[key] = newValue;
        } else {
          diffMap[key] = newValue;
        }
      }
    } else {}
  });

  newFields.forEach((key, newValue) {
    if (!oldFields.containsKey(key)) {
      diffMap[key] = newValue;
    }
  });

  if (diffMap.isEmpty) {
    return 'No differences found';
  } else {
    var diffString = '$className {';
    diffMap.forEach((key, value) {
      final valueStr = value.toString();

      if (_isListWithEntities(valueStr)) {
        diffString += ' $key: $valueStr,';
      } else {
        diffString += ' $key: $valueStr,';
      }
    });

    if (diffString.endsWith(',')) {
      diffString = diffString.substring(0, diffString.length - 1);
    }
    diffString += ' }';

    return diffString.format();
  }
}

bool _isListWithEntities(String value) {
  if (!_isNestedList(value)) return false;

  final contentStartIndex = value.indexOf('[') + 1;
  final contentEndIndex = value.lastIndexOf(']');

  if (contentStartIndex >= contentEndIndex) return false;

  final content = value.substring(contentStartIndex, contentEndIndex).trim();

  return RegExp(r'\w+\s*\{').hasMatch(content);
}

String _extractClassName(String str) {
  final braceIndex = str.indexOf('{');
  if (braceIndex == -1) return '';

  return str.substring(0, braceIndex).trim();
}

Map<String, String> _extractFields(String str) {
  final fields = <String, String>{};

  final startIndex = str.indexOf('{');
  final endIndex = str.lastIndexOf('}');

  if (startIndex == -1 || endIndex == -1 || startIndex >= endIndex) {
    return fields;
  }

  final content = str.substring(startIndex + 1, endIndex).trim();

  var index = 0;
  while (index < content.length) {
    final colonIndex = content.indexOf(':', index);
    if (colonIndex == -1) break;

    final fieldName = content.substring(index, colonIndex).trim();

    final valueStart = colonIndex + 1;
    final valueEnd = _findValueEnd(content, valueStart);

    var fieldValue = content.substring(valueStart, valueEnd).trim();

    if (fieldValue.endsWith(',')) {
      fieldValue = fieldValue.substring(0, fieldValue.length - 1).trim();
    }

    fields[fieldName] = fieldValue;
    index = valueEnd + 1;
  }

  return fields;
}

int _findValueEnd(String content, int startIndex) {
  var index = startIndex;
  var depth = 0;

  while (index < content.length && content[index] == ' ') {
    index++;
  }

  if (index < content.length) {
    if (content[index] == '{') {
      depth = 1;
      index++;

      while (index < content.length && depth > 0) {
        if (content[index] == '{') depth++;
        if (content[index] == '}') depth--;
        index++;
      }

      while (index < content.length && content[index] != ',') {
        index++;
      }

      return index;
    } else if (content[index] == '[') {
      depth = 1;
      index++;

      while (index < content.length && depth > 0) {
        if (content[index] == '[') depth++;
        if (content[index] == ']') depth--;
        index++;
      }

      while (index < content.length && content[index] != ',') {
        index++;
      }

      return index;
    } else {
      while (index < content.length && content[index] != ',') {
        index++;
      }

      return index;
    }
  }

  return content.length;
}

bool _isNestedObject(String value) {
  final newValue = value.trim();
  return newValue.contains('{') && newValue.contains('}');
}

bool _isNestedList(String value) {
  final newValue = value.trim();
  return newValue.startsWith('[') && newValue.endsWith(']');
}

DummyObject _createDummyObject(String objectStr) {
  return DummyObject(objectStr);
}

class DummyObject {
  const DummyObject(this.representation);

  final String representation;

  @override
  String toString() {
    return representation;
  }
}
