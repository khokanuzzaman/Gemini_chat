import 'package:flutter/material.dart';

/// WCAG 2.x contrast ratio between two opaque colours (1.0 – 21.0).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

const Color _white = Color(0xFFFFFFFF);
const Color _ink = Color(0xFF1B1733);

/// [color] nudged until it reads at least [minRatio]:1 on [background]
/// (default 4.5:1, the WCAG AA text threshold).
///
/// For colours that come from DATA rather than the theme — a category, wallet
/// or status accent — so a label drawn in that accent stays legible without
/// every call site checking. Moves lightness only (darker on a light
/// background, lighter on a dark one), so the hue family is preserved. A colour
/// that already passes is returned unchanged.
///
/// [background] must be opaque: blend a tint over its surface first with
/// `Color.alphaBlend`.
Color readableOn(Color color, Color background, {double minRatio = 4.5}) {
  if (contrastRatio(color, background) >= minRatio) {
    return color;
  }

  final hsl = HSLColor.fromColor(color);
  final towardDark = background.computeLuminance() > 0.5;

  var lightness = hsl.lightness;
  for (var i = 0; i < 100; i++) {
    lightness += towardDark ? -0.01 : 0.01;
    if (lightness <= 0 || lightness >= 1) {
      break;
    }
    final candidate = hsl.withLightness(lightness).toColor();
    if (contrastRatio(candidate, background) >= minRatio) {
      return candidate;
    }
  }
  // Extreme background/colour pair: fall back to the extreme that reads.
  return towardDark ? _ink : _white;
}

/// White or the dark ink, whichever reads better on [fill]. For fills that
/// come from DATA (e.g. a selected chip in a category colour).
Color labelOnFill(Color fill) {
  return contrastRatio(_white, fill) >= contrastRatio(_ink, fill)
      ? _white
      : _ink;
}
