class GraphConfig {
  const GraphConfig({
    required this.path,
    required this.title,
    required this.primaryModules,
    required this.section,
    this.description,
    this.includeDependencies = true,
    this.highlightPrimary = true,
  });

  final String path;
  final String title;
  final Set<String> primaryModules;
  final String section;
  final String? description;
  final bool includeDependencies;
  final bool highlightPrimary;
}

String? classifyModule(String moduleName) {
  if (moduleName.startsWith('common_') || moduleName.contains('_common')) {
    return 'common';
  }
  if (moduleName.startsWith('core_') || moduleName.contains('_core')) {
    return 'core';
  }
  if (moduleName.startsWith('ui_') || moduleName.contains('_ui')) {
    return 'ui';
  }
  if (moduleName.contains('_presentation') || moduleName.endsWith('_ui')) {
    return 'presentation';
  }
  if (moduleName.contains('_domain') || moduleName.contains('_business')) {
    return 'domain';
  }
  if (moduleName.contains('_data') || moduleName.contains('_repository')) {
    return 'data';
  }

  return null;
}

String moduleEdgeColor(String moduleName) {
  switch (classifyModule(moduleName)) {
    case 'presentation':
      return '#0277bd';
    case 'domain':
      return '#7b1fa2';
    case 'data':
      return '#2e7d32';
    case 'ui':
      return '#f57c00';
    case 'common':
      return '#c2185b';
    case 'core':
      return '#00695c';
    default:
      return '#546e7a';
  }
}
