import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:workkit/features/image_tools/domain/image_toolkit_engine.dart';

enum _ImageTaskKind { compress, resize, crop, convert, removeMetadata }

class DartImageToolkitEngine implements ImageToolkitEngine {
  const DartImageToolkitEngine();

  @override
  Future<ImageToolkitOutput> compress(
    String sourcePath, {
    int quality = 80,
  }) {
    return _run(
      sourcePath,
      kind: _ImageTaskKind.compress,
      format: ImageOutputFormat.fromPath(sourcePath),
      quality: quality,
    );
  }

  @override
  Future<ImageToolkitOutput> resize(
    String sourcePath, {
    int? width,
    int? height,
    bool maintainAspect = true,
  }) {
    if ((width == null || width <= 0) && (height == null || height <= 0)) {
      throw const FormatException('Enter a positive width or height.');
    }
    if (!maintainAspect &&
        (width == null || width <= 0 || height == null || height <= 0)) {
      throw const FormatException(
        'Width and height are both required when aspect ratio is unlocked.',
      );
    }
    return _run(
      sourcePath,
      kind: _ImageTaskKind.resize,
      format: ImageOutputFormat.fromPath(sourcePath),
      width: width,
      height: height,
      maintainAspect: maintainAspect,
    );
  }

  @override
  Future<ImageToolkitOutput> crop(
    String sourcePath, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    if (x < 0 || y < 0 || width <= 0 || height <= 0) {
      throw const FormatException(
        'Crop origin must be 0 or greater and crop size must be positive.',
      );
    }
    return _run(
      sourcePath,
      kind: _ImageTaskKind.crop,
      format: ImageOutputFormat.fromPath(sourcePath),
      x: x,
      y: y,
      width: width,
      height: height,
    );
  }

  @override
  Future<ImageToolkitOutput> convert(
    String sourcePath,
    ImageOutputFormat format, {
    int quality = 90,
  }) {
    return _run(
      sourcePath,
      kind: _ImageTaskKind.convert,
      format: format,
      quality: quality,
    );
  }

  @override
  Future<ImageToolkitOutput> removeMetadata(String sourcePath) {
    return _run(
      sourcePath,
      kind: _ImageTaskKind.removeMetadata,
      format: ImageOutputFormat.fromPath(sourcePath),
      removeMetadata: true,
    );
  }

  Future<ImageToolkitOutput> _run(
    String sourcePath, {
    required _ImageTaskKind kind,
    required ImageOutputFormat format,
    int quality = 90,
    int? x,
    int? y,
    int? width,
    int? height,
    bool maintainAspect = true,
    bool removeMetadata = false,
  }) async {
    final File source = File(sourcePath);
    if (!await source.exists()) {
      throw const ImageToolkitException('The selected image is no longer available.');
    }
    final int normalizedQuality = quality.clamp(1, 100).toInt();
    final Directory directory = await Directory.systemTemp.createTemp('workkit_image_');
    final String outputPath = '${directory.path}/output.${format.extension}';
    try {
      final List<int> dimensions = await Isolate.run<List<int>>(
        () => _processImage(
          sourcePath: sourcePath,
          outputPath: outputPath,
          kind: kind,
          format: format,
          quality: normalizedQuality,
          x: x,
          y: y,
          width: width,
          height: height,
          maintainAspect: maintainAspect,
          removeMetadata: removeMetadata,
        ),
      );
      final File output = File(outputPath);
      return ImageToolkitOutput(
        path: output.path,
        tempDirectory: directory.path,
        width: dimensions[0],
        height: dimensions[1],
        sizeBytes: await output.length(),
        format: format,
      );
    } on FormatException {
      if (await directory.exists()) await directory.delete(recursive: true);
      rethrow;
    } catch (error) {
      if (await directory.exists()) await directory.delete(recursive: true);
      if (error is ImageToolkitException) rethrow;
      throw ImageToolkitException('Image processing failed: $error');
    }
  }

  @override
  Future<void> cleanup(ImageToolkitOutput output) async {
    final Directory directory = Directory(output.tempDirectory);
    if (await directory.exists() && directory.path.contains('workkit_image_')) {
      await directory.delete(recursive: true);
    }
  }
}

Future<List<int>> _processImage({
  required String sourcePath,
  required String outputPath,
  required _ImageTaskKind kind,
  required ImageOutputFormat format,
  required int quality,
  required int? x,
  required int? y,
  required int? width,
  required int? height,
  required bool maintainAspect,
  required bool removeMetadata,
}) async {
  final Uint8List bytes = await File(sourcePath).readAsBytes();
  img.Image? decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Unsupported or damaged image file.');
  }
  decoded = img.bakeOrientation(decoded);
  img.Image result = decoded;

  switch (kind) {
    case _ImageTaskKind.compress:
    case _ImageTaskKind.convert:
    case _ImageTaskKind.removeMetadata:
      break;
    case _ImageTaskKind.resize:
      if (maintainAspect) {
        final int? requestedWidth = width != null && width > 0 ? width : null;
        final int? requestedHeight = height != null && height > 0 ? height : null;
        if (requestedWidth != null && requestedHeight != null) {
          final double scale = <double>[
            requestedWidth / decoded.width,
            requestedHeight / decoded.height,
          ].reduce((a, b) => a < b ? a : b);
          final int targetWidth =
              (decoded.width * scale).round().clamp(1, requestedWidth).toInt();
          final int targetHeight =
              (decoded.height * scale).round().clamp(1, requestedHeight).toInt();
          result = img.copyResize(
            decoded,
            width: targetWidth,
            height: targetHeight,
            interpolation: img.Interpolation.linear,
          );
        } else {
          result = img.copyResize(
            decoded,
            width: requestedWidth,
            height: requestedHeight,
            interpolation: img.Interpolation.linear,
          );
        }
      } else {
        result = img.copyResize(
          decoded,
          width: width,
          height: height,
          interpolation: img.Interpolation.linear,
        );
      }
    case _ImageTaskKind.crop:
      final int cropX = x ?? 0;
      final int cropY = y ?? 0;
      final int cropWidth = width ?? 0;
      final int cropHeight = height ?? 0;
      if (cropX + cropWidth > decoded.width ||
          cropY + cropHeight > decoded.height) {
        throw const FormatException('Crop rectangle extends outside the image.');
      }
      result = img.copyCrop(
        decoded,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );
  }

  if (removeMetadata || kind == _ImageTaskKind.removeMetadata) {
    result.exif.clear();
    result.textData = null;
    result.iccProfile = null;
  }

  final Uint8List encoded = switch (format) {
    ImageOutputFormat.jpg => img.encodeJpg(result, quality: quality),
    ImageOutputFormat.png => img.encodePng(result, level: 9),
    ImageOutputFormat.webp => img.encodeWebP(result),
  };
  await File(outputPath).writeAsBytes(encoded, flush: true);
  return <int>[result.width, result.height];
}
