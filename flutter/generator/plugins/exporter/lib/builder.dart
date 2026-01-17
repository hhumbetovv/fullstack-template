import 'package:build/build.dart';
import 'package:gen_exporter/src/builder.dart';

Builder exporterBuilder(BuilderOptions options) {
  return ExporterBuilder(options: options);
}
