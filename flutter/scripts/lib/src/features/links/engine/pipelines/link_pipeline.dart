import 'package:scripts/src/core/stage/runner.dart';
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

class LinkPipeline {
  const LinkPipeline(this._linkCreator);

  final LinkCreator _linkCreator;

  Future<LinkContext> run(LinkContext context) {
    return StageRunner<LinkContext>(
      stages: <Stage<LinkContext>>[
        _CreateLinksStage(_linkCreator),
        _ReportLinksStage(),
      ],
    ).run(context);
  }
}

class _CreateLinksStage implements Stage<LinkContext> {
  _CreateLinksStage(this._linkCreator);

  final LinkCreator _linkCreator;

  @override
  String get name => 'create-links';

  @override
  Future<LinkContext> run(LinkContext context) async {
    context.summary = await _linkCreator.create(
      fileName: context.fileName,
      outputDir: context.outputDir,
    );
    return context;
  }
}

class _ReportLinksStage implements Stage<LinkContext> {
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
