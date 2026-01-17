import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/links/domain/adapters/link_creator.dart';
import 'package:scripts/src/features/links/engine/pipelines/link/link_context.dart';
import 'package:scripts/src/features/links/engine/stages/link/create_links_stage.dart';
import 'package:scripts/src/features/links/engine/stages/link/report_links_stage.dart';

class LinkPipeline {
  const LinkPipeline(this._linkCreator);

  final LinkCreator _linkCreator;

  Future<LinkContext> run(LinkContext context) {
    return StageRunner<LinkContext>(
      stages: <Stage<LinkContext>>[
        CreateLinksStage(_linkCreator),
        ReportLinksStage(),
      ],
    ).run(context);
  }
}
