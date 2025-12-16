enum YamlIncludeType {
  yaml,
  raw,
}

/// Represents a `!include` node encountered while parsing YAML.
class YamlIncludeNode {
  const YamlIncludeNode({
    required this.source,
    required this.absolutePath,
    required this.type,
    required this.value,
  });

  /// Path string exactly as written in the YAML file.
  final String source;

  /// Absolute path of the included file.
  final String absolutePath;

  /// Whether to treat the include as parsed YAML or literal text.
  final YamlIncludeType type;

  /// Parsed value from the included file (YAML or raw text).
  final dynamic value;
}
