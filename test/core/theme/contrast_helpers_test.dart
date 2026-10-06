import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/core/theme/contrast.dart';

void main() {
  const white = Color(0xFFFFFFFF);
  const darkSurface = Color(0xFF221E33);

  group('readableOn', () {
    test('leaves an already-readable colour untouched', () {
      const ink = Color(0xFF1B1733);
      expect(readableOn(ink, white), ink);
    });

    test('darkens a too-light accent on a light background to >= 4.5:1', () {
      const orange = Color(
        0xFFFF6D00,
      ); // category "food" — only ~2.9:1 on white
      final result = readableOn(orange, white);
      expect(contrastRatio(result, white), greaterThanOrEqualTo(4.5));
    });

    test('keeps the hue family while darkening', () {
      const green = Color(0xFF2E9E6B);
      final result = readableOn(green, white);
      final h1 = HSLColor.fromColor(green).hue;
      final h2 = HSLColor.fromColor(result).hue;
      expect((h1 - h2).abs(), lessThan(8));
    });

    test('lightens a too-dark accent on a dark background to >= 4.5:1', () {
      const deepIndigo = Color(0xFF3A2F86);
      final result = readableOn(deepIndigo, darkSurface);
      expect(contrastRatio(result, darkSurface), greaterThanOrEqualTo(4.5));
    });

    test('works against a tinted (alpha-blended) chip background', () {
      const yellow = Color(0xFFFBBC04);
      final tint = Color.alphaBlend(yellow.withValues(alpha: 0.08), white);
      final result = readableOn(yellow, tint);
      expect(contrastRatio(result, tint), greaterThanOrEqualTo(4.5));
    });
  });

  group('labelOnFill', () {
    test('picks white on a deep fill', () {
      expect(labelOnFill(const Color(0xFF5647C4)), white);
    });

    test('picks dark ink on a light fill', () {
      final label = labelOnFill(const Color(0xFFFBBC04));
      expect(label, isNot(white));
      expect(
        contrastRatio(label, const Color(0xFFFBBC04)),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('always returns the better-contrasting of white / ink', () {
      for (final fill in const [
        Color(0xFFFF6D00),
        Color(0xFF2E9E6B),
        Color(0xFFE91E63),
        Color(0xFF00897B),
        Color(0xFF9334E6),
      ]) {
        final label = labelOnFill(fill);
        final other = label == white ? const Color(0xFF1B1733) : white;
        expect(
          contrastRatio(label, fill),
          greaterThanOrEqualTo(contrastRatio(other, fill)),
        );
      }
    });
  });
}
