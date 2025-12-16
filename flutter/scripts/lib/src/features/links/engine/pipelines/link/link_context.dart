import 'package:scripts/src/features/links/domain/adapters/link_creator.dart';

class LinkContext {
  LinkContext({
    required this.fileName,
    required this.outputDir,
    this.label,
  });

  final String fileName;
  final String outputDir;
  final String? label;

  LinkSummary? summary;
  int exitCode = 0;
}
