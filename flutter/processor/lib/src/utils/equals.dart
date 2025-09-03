bool isEquals(dynamic a, dynamic b) {
  if (identical(a, b) || a == b) return true;

  if (a == null || b == null) return false;

  if (a is List && b is List) return _equalsList(a, b);

  if (a is Map && b is Map) return _equalsMap(a, b);

  if (a is Set && b is Set) return _equalsSet(a, b);

  return false;
}

bool _equalsList(List<dynamic> a, List<dynamic> b) {
  if (a.length != b.length) return false;

  if (a.length < 100) {
    for (var i = 0; i < a.length; i++) {
      if (!isEquals(a[i], b[i])) return false;
    }
  } else {
    return List.generate(a.length, (i) => isEquals(a[i], b[i])).every((result) => result);
  }
  return true;
}

bool _equalsSet(Set<dynamic> a, Set<dynamic> b) {
  if (a.length != b.length) return false;

  for (final e in a) {
    var foundMatch = false;
    for (final other in b) {
      if (isEquals(e, other)) {
        foundMatch = true;
        break;
      }
    }
    if (!foundMatch) return false;
  }
  return true;
}

bool _equalsMap(Map<dynamic, dynamic> a, Map<dynamic, dynamic> b) {
  if (a.length != b.length) return false;

  for (final key in a.keys) {
    var foundKeyMatch = false;
    final value1 = a[key];

    for (final otherKey in b.keys) {
      if (isEquals(key, otherKey)) {
        foundKeyMatch = true;
        final value2 = b[otherKey];
        if (!isEquals(value1, value2)) return false;
        break;
      }
    }

    if (!foundKeyMatch) return false;
  }
  return true;
}
