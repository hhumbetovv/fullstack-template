import '../../core/core.dart';
import 'link_creator.dart';

Future<int> runBuildLinksFeature() async {
  Console.write('=====================================');
  Console.write('    Build Symlinks Creator');
  Console.write('=====================================');

  final summary = await createSymlinks(
    fileName: 'build.yaml',
    outputDir: 'yaml/builds',
  );

  _reportSummary(summary);
  return summary.failed > 0 ? 1 : 0;
}

Future<int> runPubspecLinksFeature() async {
  Console.write('=====================================');
  Console.write('    Pubspec Symlinks Creator');
  Console.write('=====================================');

  final summary = await createSymlinks(
    fileName: 'pubspec.yaml',
    outputDir: 'yaml/pubspecs',
  );

  _reportSummary(summary);
  return summary.failed > 0 ? 1 : 0;
}

Future<int> runYamlLinksFeature() async {
  Console.write('=== Pubspec Symlinks ===');
  final pubspecSummary = await createSymlinks(
    fileName: 'pubspec.yaml',
    outputDir: 'yaml/pubspecs',
  );

  Console.write('\n=== Build Symlinks ===');
  final buildSummary = await createSymlinks(
    fileName: 'build.yaml',
    outputDir: 'yaml/builds',
  );

  Console.write('\n=====================================');
  Console.success(
    '✓ Pubspec symlinks: ${pubspecSummary.created}, build symlinks: ${buildSummary.created}',
  );
  final failures = pubspecSummary.failed + buildSummary.failed;
  if (failures > 0) {
    Console.error('✗ Failures encountered: $failures');
  }
  Console.write('=====================================');

  return failures > 0 ? 1 : 0;
}

void _reportSummary(LinkSummary summary) {
  Console.write('\n=====================================');
  Console.success('✓ Total symlinks created: ${summary.created}');
  if (summary.failed > 0) {
    Console.error('✗ Failed: ${summary.failed}');
  }
  Console.write('=====================================');

  if (summary.failed > 0) {
    Console.error('Some symlinks failed to create.');
  } else {
    Console.success('Script completed successfully!');
  }
}
