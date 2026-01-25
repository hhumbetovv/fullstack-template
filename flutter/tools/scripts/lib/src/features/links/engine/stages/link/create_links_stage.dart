import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/links/domain/adapters/link_creator.dart';
import 'package:scripts/src/features/links/engine/pipelines/link/link_context.dart';

class CreateLinksStage implements Stage<LinkContext> {
  CreateLinksStage(this._linkCreator);

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
