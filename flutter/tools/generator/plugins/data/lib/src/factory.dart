import 'package:code_builder/code_builder.dart';
import 'package:gen_core/base.dart';
import 'package:processor/public.dart';

import 'factory/components/class_builder.dart';
import 'factory/components/extensions_builder.dart';

class DataFactory extends BaseFactory<DataConfig> {
  bool get generateCopy => true;
  bool get generateToString => true;
  bool get generateApply => true;
  bool get generateEquatable => true;

  List<Reference> getAdditionalImplements(DataConfig config) => [];
  List<Method> getAdditionalMethods(DataConfig config) => [];

  late final DataExtensionsBuilder _extensionsBuilder = DataExtensionsBuilder(
    writeSpec: writeSpec,
  );

  @override
  void build(DataConfig config) {
    DataClassBuilder(
      writeSpec: writeSpec,
      generateEquatable: generateEquatable,
      generateToString: generateToString,
      getAdditionalImplements: getAdditionalImplements,
      getAdditionalMethods: getAdditionalMethods,
    ).writeClass(config);
    _extensionsBuilder.writeGetters(config);

    if (generateCopy) _extensionsBuilder.writeCopy(config);
    if (generateApply) _extensionsBuilder.writeApply(config);
  }
}
