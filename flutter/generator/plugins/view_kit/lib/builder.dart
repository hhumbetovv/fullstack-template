import 'package:build/build.dart';
import 'package:gen_view_kit/src/provider/builder.dart';
import 'package:gen_view_kit/src/view/builder.dart';
import 'package:gen_view_kit/src/view_model/builder.dart';

Builder viewBuilder(BuilderOptions options) {
  return ViewBuilder(options: options);
}

Builder providerBuilder(BuilderOptions options) {
  return ProviderBuilder(options: options);
}

Builder viewModelBuilder(BuilderOptions options) {
  return ViewModelBuilder(options: options);
}
