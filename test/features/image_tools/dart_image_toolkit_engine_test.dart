import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:workkit/features/image_tools/data/dart_image_toolkit_engine.dart';
import 'package:workkit/features/image_tools/domain/image_toolkit_engine.dart';

void main() {
  late Directory directory;
  const DartImageToolkitEngine engine = DartImageToolkitEngine();

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('workkit_image_test_');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  Future<String> createPng({bool withMetadata = false}) async {
    final img.Image image = img.Image(width: 120, height: 80);
    img.fill(image, color: img.ColorRgb8(40, 120, 200));
    if (withMetadata) {
      image.textData = <String, String>{'Author': 'WorkKit'};
    }
    final String path = '${directory.path}/source.png';
    await File(path).writeAsBytes(img.encodePng(image), flush: true);
    return path;
  }

  test('resizes while maintaining aspect ratio', () async {
    final String source = await createPng();
    final ImageToolkitOutput output = await engine.resize(
      source,
      width: 60,
      maintainAspect: true,
    );
    addTearDown(() => engine.cleanup(output));

    expect(output.width, 60);
    expect(output.height, 40);
    expect(await File(output.path).exists(), isTrue);
  });

  test('crops exact rectangle', () async {
    final String source = await createPng();
    final ImageToolkitOutput output = await engine.crop(
      source,
      x: 10,
      y: 5,
      width: 50,
      height: 30,
    );
    addTearDown(() => engine.cleanup(output));

    expect(output.width, 50);
    expect(output.height, 30);
  });

  test('converts PNG to lossless WebP', () async {
    final String source = await createPng();
    final ImageToolkitOutput output = await engine.convert(
      source,
      ImageOutputFormat.webp,
    );
    addTearDown(() => engine.cleanup(output));

    expect(output.path, endsWith('.webp'));
    expect(img.decodeWebP(await File(output.path).readAsBytes()), isNotNull);
  });

  test('removes embedded PNG text metadata', () async {
    final String source = await createPng(withMetadata: true);
    final img.Image original = img.decodePng(await File(source).readAsBytes())!;
    expect(original.textData?['Author'], 'WorkKit');

    final ImageToolkitOutput output = await engine.removeMetadata(source);
    addTearDown(() => engine.cleanup(output));
    final img.Image sanitized = img.decodePng(await File(output.path).readAsBytes())!;

    expect(sanitized.textData?['Author'], isNull);
  });

  test('rejects crop rectangles outside the image', () async {
    final String source = await createPng();
    await expectLater(
      engine.crop(source, x: 100, y: 70, width: 30, height: 30),
      throwsA(isA<FormatException>()),
    );
  });
}
