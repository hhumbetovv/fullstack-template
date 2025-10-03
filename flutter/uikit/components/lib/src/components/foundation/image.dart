import 'package:flutter/widgets.dart';

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
    return Image.asset(
      path,
      package: 'ui_foundation',
      width: width,
      height: height,
    );
  }
}
