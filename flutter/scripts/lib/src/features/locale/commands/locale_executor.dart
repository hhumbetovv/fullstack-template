import 'package:scripts/src/features/locale/engine/pipelines/locale/locale_context.dart';
import 'package:scripts/src/features/locale/engine/pipelines/locale_pipeline.dart';

class LocaleExecutor {
  const LocaleExecutor();

  Future<int> run({
    required String inputPath,
    required String outputPath,
  }) async {
    const pipeline = LocalePipeline();
    final context = await pipeline.run(
      LocaleContext(inputPath: inputPath, outputPath: outputPath),
    );
    return context.exitCode;
  }
}
