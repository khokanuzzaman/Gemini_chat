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
  for (final entry in fonts.entries) {
    final bytes = await File(entry.value).readAsBytes();
    final loader = FontLoader(entry.key)
      ..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
    await loader.load();
  }
}
