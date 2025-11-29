import 'package:gen_core/base.dart';
import 'package:processor/public.dart';

import 'components/base_class_builder.dart';
import 'components/context_methods_builder.dart';
import 'components/contract_builder.dart';

class ViewModelFactory extends BaseFactory<ViewModelConfig> {
  @override
  void build(ViewModelConfig config) {
    ViewModelContractBuilder(
        buffer: buffer,
        writeSpec: writeSpec,
      )
      ..writeStateTypedef(config)
      ..writeIntentContract(config)
      ..writeEffectContract(config);

    ViewModelBaseClassBuilder(
      writeSpec: writeSpec,
    ).writeBaseClass(config);

    ViewModelContextMethodsBuilder(
      writeSpec: writeSpec,
    ).writeContextMethods(config);
  }
}
