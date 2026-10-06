import 'dart:io';

import 'package:flutter/services.dart';

/// `flutter_test` does NOT load the fonts declared in pubspec.yaml — without
/// this every glyph is drawn in the Ahem box font (width = chars × fontSize) and
/// any layout/overflow assertion is meaningless. Call once from `setUpAll`.
Future<void> loadAppFonts() async {
  const fonts = <String, String>{
    'Inter': 'assets/fonts/Inter-Variable.ttf',
    'Sora': 'assets/fonts/Sora-Variable.ttf',
    'NotoSansBengali': 'assets/fonts/NotoSansBengali-Variable.ttf',
  };
  // Material Icons, so rendered previews show real icons instead of boxes.
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final icons = File(
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (icons.existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(
          Future.value(
            ByteData.sublistView(Uint8List.fromList(icons.readAsBytesSync())),
          ),
        );
      await loader.load();
    }
  }
  for (final entry in fonts.entries) {
    final bytes = await File(entry.value).readAsBytes();
    final loader = FontLoader(entry.key)
      ..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
    await loader.load();
  }
}
