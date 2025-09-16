import 'package:build/build.dart';
import 'package:gen_palette/src/palette/builder.dart';
import 'package:gen_palette/src/root_palette/builder.dart';

Builder paletteBuilder(BuilderOptions options) {
  return PaletteBuilder(options: options);
}

Builder rootPaletteBuilder(BuilderOptions options) {
  return RootPaletteBuilder(options: options);
}
