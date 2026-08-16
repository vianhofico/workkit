import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const int _size = 1024;
const String _outputPath = '.generated/workkit_launcher.png';

void main() {
  final img.Image image = img.Image(width: _size, height: _size);

  for (int y = 0; y < _size; y++) {
    for (int x = 0; x < _size; x++) {
      final (int r, int g, int b) = _background(x, y);
      image.setPixelRgb(x, y, r, g, b);
    }
  }

  _fillPolygon(
    image,
    const <_Point>[
      _Point(278, 158),
      _Point(610, 158),
      _Point(760, 308),
      _Point(760, 710),
      _Point(278, 710),
    ],
    248,
    250,
    255,
  );

  _fillPolygon(
    image,
    const <_Point>[
      _Point(610, 158),
      _Point(760, 308),
      _Point(650, 308),
      _Point(610, 268),
    ],
    221,
    230,
    255,
  );

  _fillCapsule(image, 356, 318, 482, 318, 16, 205, 216, 250);
  _fillCapsule(image, 356, 386, 532, 386, 16, 205, 216, 250);

  _fillCapsule(image, 414, 550, 526, 657, 34, 255, 255, 255);
  _fillCapsule(image, 526, 657, 786, 402, 34, 255, 255, 255);

  _fillCircle(image, 391, 783, 94, 255, 255, 255);
  _restoreCircle(image, 391, 783, 49);
  _restorePolygon(
    image,
    const <_Point>[
      _Point(391, 783),
      _Point(470, 704),
      _Point(486, 742),
      _Point(424, 806),
    ],
  );
  _fillCapsule(image, 430, 748, 575, 604, 31, 255, 255, 255);

  final Directory outputDirectory = Directory('.generated');
  outputDirectory.createSync(recursive: true);
  File(_outputPath).writeAsBytesSync(img.encodePng(image));
  stdout.writeln('Generated WorkKit launcher source: $_outputPath');
}

(int, int, int) _background(int x, int y) {
  final double tx = x / (_size - 1);
  final double ty = y / (_size - 1);
  final double t = (0.55 * tx + 0.45 * ty).clamp(0.0, 1.0);

  const int r1 = 36;
  const int g1 = 152;
  const int b1 = 255;
  const int r2 = 75;
  const int g2 = 53;
  const int b2 = 246;

  final double glow = math.max(
    0,
    1 - math.sqrt(math.pow(tx - 0.28, 2) + math.pow(ty - 0.18, 2)) * 1.5,
  );

  return (
    (_lerp(r1, r2, t) + 8 * glow).round().clamp(0, 255),
    (_lerp(g1, g2, t) + 9 * glow).round().clamp(0, 255),
    (_lerp(b1, b2, t) + 4 * glow).round().clamp(0, 255),
  );
}

double _lerp(num a, num b, double t) => a + (b - a) * t;

void _fillCircle(
  img.Image image,
  int cx,
  int cy,
  int radius,
  int r,
  int g,
  int b,
) {
  final int rr = radius * radius;
  for (int y = cy - radius; y <= cy + radius; y++) {
    if (y < 0 || y >= _size) continue;
    for (int x = cx - radius; x <= cx + radius; x++) {
      if (x < 0 || x >= _size) continue;
      final int dx = x - cx;
      final int dy = y - cy;
      if (dx * dx + dy * dy <= rr) {
        image.setPixelRgb(x, y, r, g, b);
      }
    }
  }
}

void _restoreCircle(img.Image image, int cx, int cy, int radius) {
  final int rr = radius * radius;
  for (int y = cy - radius; y <= cy + radius; y++) {
    if (y < 0 || y >= _size) continue;
    for (int x = cx - radius; x <= cx + radius; x++) {
      if (x < 0 || x >= _size) continue;
      final int dx = x - cx;
      final int dy = y - cy;
      if (dx * dx + dy * dy <= rr) {
        final (int r, int g, int b) = _background(x, y);
        image.setPixelRgb(x, y, r, g, b);
      }
    }
  }
}

void _fillCapsule(
  img.Image image,
  int x1,
  int y1,
  int x2,
  int y2,
  int radius,
  int r,
  int g,
  int b,
) {
  final int minX = math.max(0, math.min(x1, x2) - radius);
  final int maxX = math.min(_size - 1, math.max(x1, x2) + radius);
  final int minY = math.max(0, math.min(y1, y2) - radius);
  final int maxY = math.min(_size - 1, math.max(y1, y2) + radius);
  final double radiusSquared = radius * radius.toDouble();

  for (int y = minY; y <= maxY; y++) {
    for (int x = minX; x <= maxX; x++) {
      if (_distanceToSegmentSquared(x, y, x1, y1, x2, y2) <=
          radiusSquared) {
        image.setPixelRgb(x, y, r, g, b);
      }
    }
  }
}

double _distanceToSegmentSquared(
  num px,
  num py,
  num x1,
  num y1,
  num x2,
  num y2,
) {
  final double dx = (x2 - x1).toDouble();
  final double dy = (y2 - y1).toDouble();
  if (dx == 0 && dy == 0) {
    return math.pow(px - x1, 2).toDouble() + math.pow(py - y1, 2).toDouble();
  }
  final double t = (((px - x1) * dx + (py - y1) * dy) /
          (dx * dx + dy * dy))
      .clamp(0.0, 1.0);
  final double sx = x1 + t * dx;
  final double sy = y1 + t * dy;
  return math.pow(px - sx, 2).toDouble() + math.pow(py - sy, 2).toDouble();
}

void _fillPolygon(
  img.Image image,
  List<_Point> points,
  int r,
  int g,
  int b,
) {
  final int minX = points.map((point) => point.x).reduce(math.min);
  final int maxX = points.map((point) => point.x).reduce(math.max);
  final int minY = points.map((point) => point.y).reduce(math.min);
  final int maxY = points.map((point) => point.y).reduce(math.max);

  for (int y = minY; y <= maxY; y++) {
    for (int x = minX; x <= maxX; x++) {
      if (_insidePolygon(x + 0.5, y + 0.5, points)) {
        image.setPixelRgb(x, y, r, g, b);
      }
    }
  }
}

void _restorePolygon(img.Image image, List<_Point> points) {
  final int minX = points.map((point) => point.x).reduce(math.min);
  final int maxX = points.map((point) => point.x).reduce(math.max);
  final int minY = points.map((point) => point.y).reduce(math.min);
  final int maxY = points.map((point) => point.y).reduce(math.max);

  for (int y = minY; y <= maxY; y++) {
    for (int x = minX; x <= maxX; x++) {
      if (_insidePolygon(x + 0.5, y + 0.5, points)) {
        final (int r, int g, int b) = _background(x, y);
        image.setPixelRgb(x, y, r, g, b);
      }
    }
  }
}

bool _insidePolygon(double x, double y, List<_Point> points) {
  bool inside = false;
  for (int i = 0, j = points.length - 1; i < points.length; j = i++) {
    final _Point a = points[i];
    final _Point b = points[j];
    final bool intersects = ((a.y > y) != (b.y > y)) &&
        (x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x);
    if (intersects) inside = !inside;
  }
  return inside;
}

class _Point {
  const _Point(this.x, this.y);

  final int x;
  final int y;
}
