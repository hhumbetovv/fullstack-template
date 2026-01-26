class ExportOptions {
  ExportOptions(Map<String, dynamic> config)
      : folders = _parseFolders(config['folders']),
        publicFile = (config['public_file'] as String?)?.trim().nonEmptyOrNull ?? 'public.dart',
        packageName = config['project_name'] as String? ?? 'exports',
        _dedicatedOutputs = _parseDedicatedOutputs(config['dedicated']);

  final List<String> folders;
  final String publicFile;
  final String packageName;
  final Map<String, String> _dedicatedOutputs;

  bool isDedicated(String folder) => _dedicatedOutputs.containsKey(folder);

  String outputForFolder(String folder) => _dedicatedOutputs[folder]!;

  List<String> get outputs {
    final result = <String>{}
      ..add(publicFile)
      ..addAll(_dedicatedOutputs.values);
    return result.toList();
  }

  static List<String> _parseFolders(dynamic value) {
    final entries = <String>[];
    if (value is List) {
      for (final entry in value) {
        final folder = entry?.toString().trim();
        if (folder == null || folder.isEmpty) continue;
        entries.add(folder);
      }
    }
    return entries;
  }

  static Map<String, String> _parseDedicatedOutputs(dynamic value) {
    if (value == null) {
      return const {};
    }
    final outputs = <String, String>{};
    if (value is List) {
      for (final entry in value) {
        final folder = entry?.toString().trim();
        if (folder == null || folder.isEmpty) {
          continue;
        }
        outputs[folder] = _deriveOutputName(folder);
      }
      return outputs;
    }
    if (value is Map) {
      value.forEach((dynamic key, dynamic outputValue) {
        final folder = key?.toString().trim();
        if (folder == null || folder.isEmpty) {
          return;
        }
        final custom = outputValue?.toString().trim();
        final fileName = (custom == null || custom.isEmpty)
            ? _deriveOutputName(folder)
            : custom;
        outputs[folder] = fileName.endsWith('.dart') ? fileName : '$fileName.dart';
      });
      return outputs;
    }
    return const {};
  }

  static String _deriveOutputName(String folder) {
    final sanitized = folder.replaceAll(RegExp(r'[\\/]+'), '_');
    final name = sanitized.isEmpty ? 'exports' : sanitized;
    return '$name.dart';
  }
}

extension on String {
  String? get nonEmptyOrNull => isEmpty ? null : this;
}
