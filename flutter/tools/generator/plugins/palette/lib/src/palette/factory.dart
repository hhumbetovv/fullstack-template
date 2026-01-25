import 'package:gen_data/builder.dart';
import 'package:processor/public.dart';

import 'components/lerp_extension_builder.dart';

class PaletteFactory extends DataFactory {
  late final PaletteLerpBuilder _lerpBuilder = PaletteLerpBuilder(
    writeSpec: writeSpec,
  );

  @override
  bool get generateToString => false;

  @override
  bool get generateApply => false;

  @override
  bool get generateEquatable => false;

  @override
  void build(DataConfig config) {
    super.build(config);
    _lerpBuilder.writeLerpExtension(config);
  }

  String buildLerpParams(List<FieldConfig> fields) {
    return _lerpBuilder.buildInvocationParams(fields);
  }
}
