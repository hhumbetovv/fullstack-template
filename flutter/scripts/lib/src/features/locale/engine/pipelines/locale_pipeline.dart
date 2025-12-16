import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/locale/engine/pipelines/locale/locale_context.dart';
import 'package:scripts/src/features/locale/engine/stages/locale/collect_keys_stage.dart';
import 'package:scripts/src/features/locale/engine/stages/locale/validate_input_stage.dart';
import 'package:scripts/src/features/locale/engine/stages/locale/write_output_stage.dart';

class LocalePipeline {
  const LocalePipeline();

  Future<LocaleContext> run(LocaleContext context) {
    return StageRunner<LocaleContext>(
      stages: <Stage<LocaleContext>>[
        ValidateInputStage(),
        CollectKeysStage(),
        WriteOutputStage(),
      ],
    ).run(context);
  }
}
