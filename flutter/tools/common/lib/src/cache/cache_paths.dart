import 'dart:io';

import 'package:path/path.dart' as p;

/// Root directory where build cache artifacts are stored.
const String buildCacheRoot = '.dart_tool/build/cache';

/// Default filename for stored effect metadata.
const String effectsCacheFileName = 'effects_cache.json';

/// Resolves an absolute path to the build cache directory.
String buildCacheDirectory({String? root}) {
  final base = root ?? Directory.current.path;
  return p.join(base, buildCacheRoot);
}

/// Creates the fully qualified path for a cached JSON file keyed by [name] and [id].
String buildCacheFilePath({
  required String name,
  required int id,
  String? root,
}) {
  return p.join(buildCacheDirectory(root: root), '${name}_$id.json');
}

/// Resolves the location of the effect cache JSON file.
String effectsCachePath({String? root}) {
  return p.join(buildCacheDirectory(root: root), effectsCacheFileName);
}
