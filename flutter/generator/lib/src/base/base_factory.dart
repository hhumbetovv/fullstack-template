import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

abstract class BaseFactory<Config> {
  final buffer = StringBuffer();
  final formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );
  final emitter = DartEmitter();

  void build(Config config);

  String stringify(Config config) {
    buffer.clear();
    build(config);
    return buffer.toString();
  }

  void writeSpec(Spec spec) {
    buffer.writeln(formatter.format('${spec.accept(emitter)}'));
  }
}
