import 'package:build/build.dart';

import 'src/builder.dart';

export 'src/builder.dart';
export 'src/factory.dart';

Builder dataBuilder(BuilderOptions options) {
  return DataBuilder(options: options);
}
