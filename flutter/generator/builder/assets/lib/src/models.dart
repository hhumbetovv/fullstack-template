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

class AssetCollections {
  const AssetCollections({
    required this.icons,
    required this.images,
  });

  final List<IconEntry> icons;
  final List<ImageEntry> images;
}

class AssetOutputs {
  const AssetOutputs({
    required this.iconContent,
    required this.imageContent,
  });

  final String iconContent;
  final String imageContent;
}
