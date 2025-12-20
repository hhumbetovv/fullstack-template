class IconEntry {
  const IconEntry({
    required this.enumName,
    required this.assetName,
  });

  final String enumName;
  final String assetName;
}

class ImageEntry {
  const ImageEntry({
    required this.enumName,
    required this.assetName,
  });

  final String enumName;
  final String assetName;
}

class LottieEntry {
  const LottieEntry({
    required this.enumName,
    required this.assetName,
  });

  final String enumName;
  final String assetName;
}

class AssetCollections {
  const AssetCollections({
    required this.icons,
    required this.images,
    required this.lotties,
  });

  final List<IconEntry> icons;
  final List<ImageEntry> images;
  final List<LottieEntry> lotties;
}

class AssetOutputs {
  const AssetOutputs({
    required this.imageContent,
    required this.lottieContent,
  });

  final String imageContent;
  final String lottieContent;
}
