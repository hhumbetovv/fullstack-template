import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

class AnnotationScanner {
  const AnnotationScanner(this.typeChecker);

  final TypeChecker typeChecker;

  Future<bool> hasAnyTopLevelAnnotations(
    BuildStep buildStep,
    AssetId input, {
    CompilationUnit? compilationUnit,
    bool allowSyntaxErrors = false,
  }) async {
    if (!await buildStep.canRead(input)) return false;
    final lib = await buildStep.resolver.libraryFor(
      input,
      allowSyntaxErrors: allowSyntaxErrors,
    );
    final reader = LibraryReader(lib);

    if (reader.annotatedWith(typeChecker).isNotEmpty) {
      return true;
    }

    final parsed =
        compilationUnit ??
        await buildStep.resolver.compilationUnitFor(
          input,
          allowSyntaxErrors: allowSyntaxErrors,
        );

    final partIds = <AssetId>[];
    for (final directive in parsed.directives) {
      if (directive is PartDirective) {
        partIds.add(
          AssetId.resolve(
            Uri.parse(directive.uri.stringValue!),
            from: input,
          ),
        );
      }
    }

    for (final partId in partIds) {
      if (await hasAnyTopLevelAnnotations(
        buildStep,
        partId,
        allowSyntaxErrors: allowSyntaxErrors,
      )) {
        return true;
      }
    }
    return false;
  }
}
