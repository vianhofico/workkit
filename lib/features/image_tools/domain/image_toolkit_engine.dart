enum ImageOutputFormat {
  jpg('jpg'),
  png('png'),
  webp('webp');

  const ImageOutputFormat(this.extension);

  final String extension;

  static ImageOutputFormat fromPath(String path) {
    final String lower = path.toLowerCase();
    if (lower.endsWith('.png')) return ImageOutputFormat.png;
    if (lower.endsWith('.webp')) return ImageOutputFormat.webp;
    return ImageOutputFormat.jpg;
  }
}

class ImageToolkitOutput {
  const ImageToolkitOutput({
    required this.path,
    required this.tempDirectory,
    required this.width,
    required this.height,
    required this.sizeBytes,
    required this.format,
  });

  final String path;
  final String tempDirectory;
  final int width;
  final int height;
  final int sizeBytes;
  final ImageOutputFormat format;
}

class ImageToolkitException implements Exception {
  const ImageToolkitException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class ImageToolkitEngine {
  Future<ImageToolkitOutput> compress(
    String sourcePath, {
    int quality = 80,
  });

  Future<ImageToolkitOutput> resize(
    String sourcePath, {
    int? width,
    int? height,
    bool maintainAspect = true,
  });

  Future<ImageToolkitOutput> crop(
    String sourcePath, {
    required int x,
    required int y,
    required int width,
    required int height,
  });

  Future<ImageToolkitOutput> convert(
    String sourcePath,
    ImageOutputFormat format, {
    int quality = 90,
  });

  Future<ImageToolkitOutput> removeMetadata(String sourcePath);

  Future<void> cleanup(ImageToolkitOutput output);
}
