class ExportOptions {
  ExportOptions(Map<String, dynamic> config)
    : folders = (config['folders'] as List?)?.cast<String>() ?? const [],
      packageName = config['project_name'] as String? ?? 'exports';

  final List<String> folders;
  final String packageName;
}
