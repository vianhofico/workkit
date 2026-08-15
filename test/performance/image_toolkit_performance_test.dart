import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:workkit/features/image_tools/data/dart_image_toolkit_engine.dart';
import 'package:workkit/features/image_tools/domain/image_toolkit_engine.dart';

void main() {
  test('representative local image resize stays within regression budget', () async {
    final Directory directory =
        await Directory.systemTemp.createTemp('workkit_perf_test_');
    const DartImageToolkitEngine engine = DartImageToolkitEngine();
    ImageToolkitOutput? output;
    try {
      final img.Image source = img.Image(width: 900, height: 900);
      img.fill(source, color: img.ColorRgb8(80, 120, 180));
      final File input = File('${directory.path}/input.png');
      await input.writeAsBytes(img.encodePng(source), flush: true);

      final Stopwatch stopwatch = Stopwatch()..start();
      output = await engine.resize(input.path, width: 450);
      stopwatch.stop();

      expect(output.width, 450);
      expect(output.height, 450);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 20)));
    } finally {
      if (output != null) {
        await engine.cleanup(output);
      }
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
  });
}
