// R5: the brand set is wired into the launcher icon, the splash screens and the
// app — from the files in assets/brand/ (never redrawn).

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/core/assets/app_icon.dart';
import 'package:gemini_chat/core/theme/app_theme.dart';
import 'package:gemini_chat/features/splash/splash_screen.dart';

/// (width, height, hasAlpha) from a PNG's IHDR (+ tRNS).
({int w, int h, bool alpha}) _png(String path) {
  final bytes = File(path).readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  final colourType = bytes[25];
  return (
    w: data.getUint32(16),
    h: data.getUint32(20),
    alpha:
        colourType == 4 ||
        colourType == 6 ||
        latin1.decode(bytes, allowInvalid: true).contains('tRNS'),
  );
}

void main() {
  const res = 'android/app/src/main/res';

  group('Android launcher icon', () {
    const adaptive = {
      'mdpi': 108,
      'hdpi': 162,
      'xhdpi': 216,
      'xxhdpi': 324,
      'xxxhdpi': 432,
    };
    const legacy = {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };

    test('adaptive layers exist at every density, right size', () {
      adaptive.forEach((density, px) {
        for (final layer in ['background', 'foreground', 'monochrome']) {
          final png = _png('$res/mipmap-$density/ic_launcher_$layer.png');
          expect((png.w, png.h), (px, px), reason: '$density $layer');
        }
        // foreground and monochrome are transparent; the background is opaque
        expect(
          _png('$res/mipmap-$density/ic_launcher_foreground.png').alpha,
          isTrue,
        );
        expect(
          _png('$res/mipmap-$density/ic_launcher_background.png').alpha,
          isFalse,
        );
      });
    });

    test('legacy icon is icon_square at every density', () {
      legacy.forEach((density, px) {
        final png = _png('$res/mipmap-$density/ic_launcher.png');
        expect((png.w, png.h), (px, px), reason: density);
      });
    });

    test('adaptive-icon XML wires background, foreground and themed layer', () {
      final xml = File(
        '$res/mipmap-anydpi-v26/ic_launcher.xml',
      ).readAsStringSync();
      expect(xml, contains('@mipmap/ic_launcher_background'));
      expect(xml, contains('@mipmap/ic_launcher_foreground'));
      expect(xml, contains('<monochrome'));
    });
  });

  test('every icon the manifest names exists (icon and roundIcon)', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final refs = RegExp(
      r'android:(?:icon|roundIcon)="@mipmap/(\w+)"',
    ).allMatches(manifest).map((m) => m.group(1)!).toSet();
    expect(refs, containsAll(['ic_launcher', 'ic_launcher_round']));
    for (final name in refs) {
      final found = Directory(res).listSync().whereType<Directory>().any(
        (d) =>
            d.path.contains('mipmap-') &&
            (File('${d.path}/$name.png').existsSync() ||
                File('${d.path}/$name.xml').existsSync()),
      );
      expect(found, isTrue, reason: '@mipmap/$name is referenced but missing');
    }
  });

  group('Android splash', () {
    test('12+ : splash_mark on #5647C4, in light AND dark', () {
      for (final dir in ['values-v31', 'values-night-v31']) {
        final xml = File('$res/$dir/styles.xml').readAsStringSync();
        expect(xml, contains('windowSplashScreenBackground'), reason: dir);
        expect(xml, contains('@color/splash_brand'), reason: dir);
        expect(xml, contains('@drawable/splash_mark'), reason: dir);
      }
      expect(
        File('$res/values/colors.xml').readAsStringSync().toLowerCase(),
        contains('#5647c4'),
      );
    });

    test('pre-12: icon_rounded on #F3F1FA light / #14121F dark', () {
      expect(
        File('$res/values/colors.xml').readAsStringSync().toLowerCase(),
        contains('#f3f1fa'),
      );
      expect(
        File('$res/values-night/colors.xml').readAsStringSync().toLowerCase(),
        contains('#14121f'),
      );
      for (final dir in ['drawable', 'drawable-night']) {
        final xml = File('$res/$dir/launch_background.xml').readAsStringSync();
        expect(xml, contains('@color/launch_canvas'), reason: dir);
        expect(xml, contains('@drawable/splash_icon'), reason: dir);
      }
      // A drawable-v21 override would shadow these on every modern phone.
      expect(Directory('$res/drawable-v21').existsSync(), isFalse);
    });

    test('splash drawables exist at every density', () {
      for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
        expect(
          File('$res/drawable-$density/splash_mark.png').existsSync(),
          isTrue,
        );
        expect(
          File('$res/drawable-$density/splash_icon.png').existsSync(),
          isTrue,
        );
      }
    });
  });

  group('iOS', () {
    test('every AppIcon is the declared size and has NO alpha', () {
      const set = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
      final images =
          (jsonDecode(File('$set/Contents.json').readAsStringSync())['images']
                  as List)
              .cast<Map<String, dynamic>>();
      expect(images, isNotEmpty);
      for (final image in images) {
        final size = double.parse((image['size'] as String).split('x').first);
        final scale = int.parse((image['scale'] as String).replaceAll('x', ''));
        final expected = (size * scale).round();
        final png = _png('$set/${image['filename']}');
        expect(png.w, expected, reason: image['filename'] as String);
        expect(png.alpha, isFalse, reason: '${image['filename']} has alpha');
      }
    });

    test('launch screen is the brand canvas with the mark, light and dark', () {
      final colors = File(
        'ios/Runner/Assets.xcassets/LaunchBackground.colorset/Contents.json',
      ).readAsStringSync().toLowerCase();
      expect(colors, contains('0xf3'));
      expect(colors, contains('0x14'));
      expect(colors, contains('dark'));
      expect(
        File(
          'ios/Runner/Base.lproj/LaunchScreen.storyboard',
        ).readAsStringSync(),
        contains('image="LaunchIcon"'),
      );
    });
  });

  group('bundling', () {
    test('only the in-app SVG is bundled; the Play icon never is', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('- assets/brand/icon_rounded.svg'));
      expect(pubspec, isNot(contains('- assets/brand/\n')));
      expect(pubspec, isNot(contains('play_store_icon')));
      expect(pubspec, isNot(contains('assets/icon/')));
      expect(File('assets/brand/play_store_icon_512.png').existsSync(), isTrue);
    });
  });

  group('in-app logo', () {
    testWidgets('PocketPilotLogo draws the brand SVG at the requested size', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Center(child: PocketPilotLogo(size: 64))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(tester.getSize(find.byType(SvgPicture)), const Size(64, 64));
    });

    for (final dark in [false, true]) {
      testWidgets('splash: mark centred on the canvas (dark=$dark)', (
        tester,
      ) async {
        var finished = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            home: SplashScreen(onFinished: () => finished = true),
          ),
        );
        await tester.pumpAndSettle();
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(
          scaffold.backgroundColor,
          dark ? const Color(0xFF14121F) : const Color(0xFFF3F1FA),
        );
        expect(find.byType(PocketPilotLogo), findsOneWidget);
        final centre = tester.getCenter(find.byType(PocketPilotLogo));
        expect(centre, tester.getCenter(find.byType(Scaffold)));
        expect(
          tester.getSize(find.byType(SvgPicture)),
          const Size(SplashScreen.markSize, SplashScreen.markSize),
        );
        await tester.pump(const Duration(seconds: 2));
        expect(finished, isTrue);
      });
    }
  });
}
