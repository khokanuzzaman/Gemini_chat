import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/features/expense/presentation/widgets/add_entry/entry_type.dart';

import '../../helpers/add_entry_harness.dart';
import '../../helpers/app_fonts.dart';

/// Review aid, not an assertion: `R2_PREVIEW=1 flutter test <this file>` renders the
/// add sheet to build/r2_preview/*.png (git-ignored) with the real fonts. The host
/// has no emoji font (wallet emojis show as boxes here only) and does not draw the
/// system keyboard (the layout reserves its space).
void main() {
  final enabled = Platform.environment['R2_PREVIEW'] == '1';

  setUpAll(() async {
    await loadAppFonts();
    await initializeDateFormatting('bn');
  });

  Future<void> shoot(
    WidgetTester tester,
    String name, {
    required EntryType type,
    Brightness brightness = Brightness.light,
    Size size = const Size(360, 800),
    double scale = 1.0,
    String keys = '',
    String? choose,
    String? note,
    bool keyboard = false,
    bool recurring = false,
  }) async {
    final env = await newAddEntryEnv();
    final key = GlobalKey();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.reset();
      tester.view.resetViewInsets();
    });
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: addEntryApp(
          env,
          initialType: type,
          brightness: brightness,
          textScale: scale,
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    for (final k in keys.split('')) {
      if (k.trim().isEmpty) continue;
      await tester.tap(find.text(k));
      await tester.pump();
    }
    if (choose != null) {
      await tester.tap(find.text(choose));
      await tester.pump();
    }
    if (recurring) {
      await tester.tap(find.text('প্রতি মাসে'));
      await tester.pump();
    }
    if (note != null) {
      await tester.ensureVisible(find.byType(TextField));
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), note);
      await tester.pumpAndSettle();
      if (keyboard) {
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
      } else {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
      }
    }
    expect(tester.takeException(), isNull);

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = Directory('build/r2_preview')..createSync(recursive: true);
      File(
        '${dir.path}/$name.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  group('R2 preview PNGs', skip: enabled ? false : 'set R2_PREVIEW=1', () {
    testWidgets(
      'expense, empty',
      (t) => shoot(t, 'add_expense_empty', type: EntryType.expense),
    );
    testWidgets(
      'expense, filled',
      (t) => shoot(
        t,
        'add_expense_filled',
        type: EntryType.expense,
        keys: '১২৫০',
        choose: 'যাতায়াত',
        note: 'রিকশা ভাড়া',
      ),
    );
    testWidgets(
      'income, filled',
      (t) => shoot(
        t,
        'add_income_filled',
        type: EntryType.income,
        keys: '৬৫০০০',
        choose: 'বেতন',
        recurring: true,
        note: 'অক্টোবরের বেতন',
      ),
    );
    testWidgets(
      'dark, filled',
      (t) => shoot(
        t,
        'add_expense_dark',
        type: EntryType.expense,
        brightness: Brightness.dark,
        keys: '১২৫০',
        choose: 'খাবার',
      ),
    );
    testWidgets(
      'note focused, keyboard up',
      (t) => shoot(
        t,
        'add_note_keyboard',
        type: EntryType.expense,
        keys: '১২৫০',
        note: 'রিকশা ভাড়া',
        keyboard: true,
      ),
    );
    testWidgets(
      'small phone 320x568, x1.3 text',
      (t) => shoot(
        t,
        'add_small_320x568_x1_3',
        type: EntryType.expense,
        size: const Size(320, 568),
        scale: 1.3,
        keys: '১২৫০',
      ),
    );
  });
}
