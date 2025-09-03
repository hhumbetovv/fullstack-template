import 'package:build/build.dart';
import 'package:generator/src/builders/data/builder.dart';
import 'package:generator/src/builders/exporter/builder.dart';
import 'package:generator/src/builders/palette/builder.dart';
import 'package:generator/src/builders/provider/builder.dart';
import 'package:generator/src/builders/view/builder.dart';
import 'package:generator/src/builders/view_model/builder.dart';

Builder paletteBuilder(BuilderOptions options) {
  return PaletteBuilder(options: options);
}

Builder exporterBuilder(BuilderOptions options) {
  return ExporterBuilder(options: options);
}

Builder dataBuilder(BuilderOptions options) {
  return DataBuilder(options: options);
}

Builder viewBuilder(BuilderOptions options) {
  return ViewBuilder(options: options);
}

Builder providerBuilder(BuilderOptions options) {
  return ProviderBuilder(options: options);
}

Builder viewModelBuilder(BuilderOptions options) {
  return ViewModelBuilder(options: options);
}
