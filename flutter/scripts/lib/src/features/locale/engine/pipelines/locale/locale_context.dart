import 'dart:io';

class LocaleContext {
  LocaleContext({
    required this.inputPath,
    required this.outputPath,
  });

  final String inputPath;
  final String outputPath;

  late Directory inputDir;
  Set<String> keys = const {};
  int exitCode = 0;
}
