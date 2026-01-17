import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';

final class UiImage extends StatelessWidget {
  const UiImage(
    this.path, {
    super.key,
    this.width,
    this.height,
  });

  final String path;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (path.endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        width: width,
        height: height,
        package: 'ui_foundation',
      );
    }
    return Image.asset(
      path,
      package: 'ui_foundation',
      width: width,
      height: height,
    );
  }
}
