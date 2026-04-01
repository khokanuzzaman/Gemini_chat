import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

void main() {
  const size = 512;
  const radius = 112.0;
  const topColor = _Rgb(26, 115, 232);
  const bottomColor = _Rgb(21, 87, 176);
  const white = _Rgb(255, 255, 255);

  final image = img.Image(width: size, height: size, numChannels: 4);

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      if (!_insideRoundedRect(x.toDouble(), y.toDouble(), size, size, radius)) {
        image.setPixelRgba(x, y, 0, 0, 0, 0);
        continue;
      }

      final t = (x + y) / ((size - 1) * 2);
      final color = _Rgb.lerp(topColor, bottomColor, t);
      image.setPixelRgba(x, y, color.r, color.g, color.b, 255);
    }
  }

  _drawStroke(image, const _Point(144, 140), const _Point(368, 140), 26, white);
  _drawStroke(image, const _Point(164, 224), const _Point(338, 224), 20, white);
  _drawStroke(image, const _Point(214, 108), const _Point(214, 390), 26, white);
  _drawStroke(image, const _Point(330, 138), const _Point(238, 236), 18, white);
  _drawStroke(image, const _Point(214, 246), const _Point(340, 352), 24, white);

  final outputDir = Directory('assets/icon');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final outputFile = File('assets/icon/app_icon.png');
  outputFile.writeAsBytesSync(img.encodePng(image));
}

bool _insideRoundedRect(
  double x,
  double y,
  int width,
  int height,
  double radius,
) {
  if (x >= radius && x <= width - radius) {
    return true;
  }
  if (y >= radius && y <= height - radius) {
    return true;
  }

  final corners = [
    _Point(radius, radius),
    _Point(width - radius, radius),
    _Point(radius, height - radius),
    _Point(width - radius, height - radius),
  ];

  for (final corner in corners) {
    final dx = x - corner.x;
    final dy = y - corner.y;
    if (dx * dx + dy * dy <= radius * radius) {
      return true;
    }
  }

  return false;
}

void _drawStroke(
  img.Image image,
  _Point from,
  _Point to,
  double thickness,
  _Rgb color,
) {
  final minX = math.max(0, math.min(from.x, to.x).floor() - thickness.toInt());
  final maxX = math.min(
    image.width - 1,
    math.max(from.x, to.x).ceil() + thickness.toInt(),
  );
  final minY = math.max(0, math.min(from.y, to.y).floor() - thickness.toInt());
  final maxY = math.min(
    image.height - 1,
    math.max(from.y, to.y).ceil() + thickness.toInt(),
  );

  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      final distance = _distanceToSegment(
        _Point(x.toDouble(), y.toDouble()),
        from,
        to,
      );
      if (distance <= thickness / 2) {
        image.setPixelRgba(x, y, color.r, color.g, color.b, 255);
      }
    }
  }
}

double _distanceToSegment(_Point point, _Point a, _Point b) {
  final dx = b.x - a.x;
  final dy = b.y - a.y;
  if (dx == 0 && dy == 0) {
    return math.sqrt(math.pow(point.x - a.x, 2) + math.pow(point.y - a.y, 2));
  }

  final t =
      (((point.x - a.x) * dx) + ((point.y - a.y) * dy)) /
      ((dx * dx) + (dy * dy));
  final clamped = t.clamp(0.0, 1.0);
  final projectionX = a.x + clamped * dx;
  final projectionY = a.y + clamped * dy;
  return math.sqrt(
    math.pow(point.x - projectionX, 2) + math.pow(point.y - projectionY, 2),
  );
}

class _Point {
  const _Point(this.x, this.y);

  final double x;
  final double y;
}

class _Rgb {
  const _Rgb(this.r, this.g, this.b);

  final int r;
  final int g;
  final int b;

  static _Rgb lerp(_Rgb start, _Rgb end, double t) {
    final value = t.clamp(0, 1).toDouble();
    return _Rgb(
      start.r + ((end.r - start.r) * value).round(),
      start.g + ((end.g - start.g) * value).round(),
      start.b + ((end.b - start.b) * value).round(),
    );
  }
}
