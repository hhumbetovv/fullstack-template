import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/links/engine/pipelines/link/link_context.dart';

class ReportLinksStage implements Stage<LinkContext> {
  @override
  String get name => 'report-links';

  @override
  Future<LinkContext> run(LinkContext context) async {
    final summary = context.summary;
    if (summary == null) {
      context.exitCode = 1;
      return context;
    }
    final failed = summary.failed;
    context.exitCode = failed > 0 ? 1 : 0;
    return context;
  }
}
