import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The bundled fonts' SIL OFL texts, in `assets/fonts/licenses/`.
///
/// OFL §2 requires the license to travel with the font; this registers them with
/// Flutter's [LicenseRegistry] so they appear on the platform licenses page
/// (`showLicensePage` / `AboutListTile`) next to the package licenses.
@visibleForTesting
const fontLicenseAssets = <String, String>{
  'Inter': 'assets/fonts/licenses/OFL-Inter.txt',
  'Sora': 'assets/fonts/licenses/OFL-Sora.txt',
  'Noto Sans Bengali': 'assets/fonts/licenses/OFL-NotoSansBengali.txt',
};

/// Call once from `main()` before `runApp`. [bundle] is for tests.
void registerFontLicenses({AssetBundle? bundle}) {
  LicenseRegistry.addLicense(() async* {
    final source = bundle ?? rootBundle;
    for (final entry in fontLicenseAssets.entries) {
      final text = await source.loadString(entry.value);
      yield LicenseEntryWithLineBreaks(<String>[entry.key], text);
    }
  });
}
