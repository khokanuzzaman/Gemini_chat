import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/features/more/presentation/screens/more_screen.dart';
import 'package:gemini_chat/features/obligations/presentation/screens/upcoming_obligations_screen.dart';
import 'package:gemini_chat/features/plan/presentation/screens/plan_screen.dart';

import '../../helpers/app_fonts.dart';
import '../../helpers/home_harness.dart';
import 'hubs_test.dart' show scenario, overdueDebt;

/// Review aid, not an assertion: `R4_PREVIEW=1 flutter test <this file>` renders the
/// hubs to build/r4_preview/*.png (git-ignored) with the real fonts. The host has no
/// emoji font and does not draw the system status/nav bars or the bottom tab bar.
void main() {
  final enabled = Platform.environment['R4_PREVIEW'] == '1';

  setUpAll(() async {
    await loadAppFonts();
    await initializeDateFormatting('bn');
  });

  Future<void> shoot(
    WidgetTester tester,
    String name,
    HomeScenario s,
    Widget home, {
    Brightness brightness = Brightness.light,
  }) async {
    final key = GlobalKey();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: homeApp(s, home: home, brightness: brightness),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = Directory('build/r4_preview')..createSync(recursive: true);
      File(
        '${dir.path}/$name.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  group('R4 preview PNGs', skip: !enabled, () {
    testWidgets(
      'plan',
      (t) => shoot(t, 'plan_populated', scenario(), const PlanScreen()),
    );
    testWidgets(
      'plan, attention',
      (t) => shoot(
        t,
        'plan_attention',
        scenario(thisMonth: 72500, debts: [overdueDebt()]),
        const PlanScreen(),
      ),
    );
    testWidgets(
      'plan, first run',
      (t) =>
          shoot(t, 'plan_first_run', HomeScenario.empty(), const PlanScreen()),
    );
    testWidgets(
      'plan, dark',
      (t) => shoot(
        t,
        'plan_dark',
        scenario(),
        const PlanScreen(),
        brightness: Brightness.dark,
      ),
    );
    testWidgets(
      'more',
      (t) => shoot(t, 'more_populated', scenario(), const MoreScreen()),
    );
    testWidgets(
      'more, sms off',
      (t) => shoot(
        t,
        'more_sms_off',
        scenario(smsEnabled: false, smsPending: 0),
        const MoreScreen(),
      ),
    );
    testWidgets(
      'more, dark',
      (t) => shoot(
        t,
        'more_dark',
        scenario(),
        const MoreScreen(),
        brightness: Brightness.dark,
      ),
    );
    testWidgets(
      'upcoming',
      (t) => shoot(
        t,
        'upcoming_list',
        scenario(),
        const UpcomingObligationsScreen(),
      ),
    );
    testWidgets(
      'upcoming, overdue',
      (t) => shoot(
        t,
        'upcoming_overdue',
        scenario(debts: [overdueDebt()]),
        const UpcomingObligationsScreen(),
      ),
    );
  });
}
