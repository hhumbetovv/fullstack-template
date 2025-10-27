import 'package:path/path.dart' as p;

/// Normalises a configuration path to Posix style and removes leading/trailing separators.
String normalizePosix(String value) {
  var normalized = value.replaceAll(r'\', '/');
  normalized = normalized.replaceAll(RegExp('/+'), '/');
  normalized = normalized.replaceAll(RegExp('^/'), '');
  normalized = normalized.replaceAll(RegExp(r'/$'), '');
  return normalized;
}

/// Ensures tooling uses a consistent system-dependent absolute path.
String normalizeSystemPath(String value) {
  return p.normalize(p.absolute(value));
}

/// Ensures workspace-relative paths start with `./` for display consistency.
String ensureDotRelative(String path) {
  if (path.startsWith('./') || path.startsWith('/')) {
    return path;
  }
  return './$path';
}
