import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/core/backup/backup_models.dart';
import 'package:gemini_chat/core/backup/backup_reminder_policy.dart';
import 'package:gemini_chat/core/utils/bangla_formatters.dart';
import 'package:gemini_chat/features/expense/presentation/widgets/home/home_sms_card.dart';

import '../../helpers/app_fonts.dart';
import '../../helpers/home_harness.dart';

Future<void> _pump(
  WidgetTester tester,
  HomeScenario scenario, {
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
  RecordingAnalyticsLogger? logger,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    homeApp(
      scenario,
      brightness: brightness,
      textScale: textScale,
      logger: logger,
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

final _backupInfo = BackupFileInfo(
  fileId: 'f',
  name: 'backup.enc',
  sizeBytes: 4096,
  modifiedAt: DateTime(2026, 10, 1),
);

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await initializeDateFormatting('bn');
  });

  group('populated', () {
    testWidgets('header: greeting over the signed-in first name', (
      tester,
    ) async {
      await _pump(tester, HomeScenario.populated());
      expect(find.text('Khokan'), findsOneWidget);
      expect(find.textMatching('শুভ'), findsOneWidget);
    });

    testWidgets('signed out: greeting only, no name', (tester) async {
      await _pump(tester, HomeScenario.populated(name: null));
      expect(find.text('Khokan'), findsNothing);
      expect(find.textMatching('শুভ'), findsOneWidget);
    });

    testWidgets('hero: মোট সম্পদ, সব ওয়ালেট মিলিয়ে, one chip per wallet', (
      tester,
    ) async {
      await _pump(tester, HomeScenario.populated());
      expect(find.text('মোট সম্পদ'), findsOneWidget);
      expect(find.text('সব ওয়ালেট মিলিয়ে'), findsOneWidget);
      for (final name in ['নগদ টাকা', 'বিকাশ', 'ব্র্যাক ব্যাংক']) {
        expect(find.textContaining(name), findsWidgets);
      }
    });

    testWidgets('এই মাসের খরচ with the % delta (less = down arrow)', (
      tester,
    ) async {
      await _pump(tester, HomeScenario.populated());
      expect(find.text('এই মাসের খরচ'), findsOneWidget);
      expect(find.text(BanglaFormatters.currency(41890)), findsOneWidget);
      expect(find.text('গত মাসের চেয়ে ২০% কম'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
    });

    testWidgets('delta chip is hidden when last month is zero', (tester) async {
      final base = HomeScenario.populated();
      await _pump(
        tester,
        HomeScenario(
          thisMonth: 41890,
          lastMonth: 0,
          wallets: base.wallets,
          expenses: base.expenses,
          incomes: base.incomes,
        ),
      );
      expect(find.textContaining('গত মাসের'), findsNothing);
      expect(find.text(BanglaFormatters.currency(41890)), findsOneWidget);
    });

    testWidgets('spent more -> muted up arrow, never "less"', (tester) async {
      final base = HomeScenario.populated();
      await _pump(
        tester,
        HomeScenario(
          thisMonth: 60000,
          lastMonth: 50000,
          wallets: base.wallets,
          expenses: base.expenses,
        ),
      );
      expect(find.text('গত মাসের চেয়ে ২০% বেশি'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    });

    testWidgets(
      'SMS card: pending count + brass CTA; ✕ hides it without losing data',
      (tester) async {
        await _pump(tester, HomeScenario.populated(smsPending: 3));
        expect(
          find.text('আপনার SMS থেকে ৩টি লেনদেন পাওয়া গেছে'),
          findsOneWidget,
        );
        expect(find.text('দেখুন ও নিশ্চিত করুন'), findsOneWidget);

        await tester.tap(find.bySemanticsLabel('পরে দেখব'));
        await tester.pumpAndSettle();
        expect(find.textContaining('SMS থেকে'), findsNothing);
      },
    );

    testWidgets('SMS card is absent with nothing pending', (tester) async {
      await _pump(tester, HomeScenario.populated(smsPending: 0));
      expect(find.text('দেখুন ও নিশ্চিত করুন'), findsNothing);
    });

    testWidgets(
      'insights: budget · upcoming (EMI + rent) · prediction · anomaly',
      (tester) async {
        await _pump(tester, HomeScenario.populated());
        expect(find.text('ইনসাইট'), findsOneWidget);
        expect(find.text('মাসিক বাজেট'), findsOneWidget);
        expect(find.text('আসছে'), findsOneWidget);
        expect(find.textContaining('City Bank'), findsWidgets);
        expect(find.textContaining('বাড়িভাড়া'), findsWidgets);
        expect(find.text('মাস শেষে আনুমানিক খরচ'), findsOneWidget);
        expect(find.text('১টি অস্বাভাবিক খরচ'), findsOneWidget);
      },
    );

    testWidgets('insights show only rows that have something to say', (
      tester,
    ) async {
      final base = HomeScenario.populated();
      await _pump(
        tester,
        HomeScenario(
          thisMonth: 1000,
          wallets: base.wallets,
          expenses: base.expenses,
        ),
      );
      expect(find.text('ইনসাইট'), findsNothing);
    });

    testWidgets(
      'recent: expenses AND income merged, newest first, EMI included',
      (tester) async {
        await _pump(tester, HomeScenario.populated());
        expect(find.text('সাম্প্রতিক লেনদেন'), findsOneWidget);
        expect(find.text('অক্টোবরের বেতন'), findsOneWidget); // income
        expect(find.text('City Bank'), findsWidgets); // EMI payment row
        expect(find.text('Uber'), findsOneWidget);
        expect(
          find.text('+${BanglaFormatters.currency(65000)}'),
          findsOneWidget,
        );
        expect(find.text('-${BanglaFormatters.currency(380)}'), findsOneWidget);
      },
    );

    testWidgets('the dropped sections are gone', (tester) async {
      await _pump(tester, HomeScenario.populated());
      expect(find.text('রিসিট স্ক্যান'), findsNothing); // quick actions
      expect(find.text('খরচ যোগ'), findsNothing);
      expect(find.text('আসছে খরচ'), findsNothing); // old recurring card
      expect(find.textContaining('ক্যাটাগরি অনুযায়ী'), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });

  group('one attention slot: restore > backup reminder', () {
    const reminder = BackupReminderDecision(show: true, daysSinceBackup: 30);

    testWidgets('both pending -> only the restore banner', (tester) async {
      await _pump(
        tester,
        HomeScenario.populated(reminder: reminder, restoreBackup: _backupInfo),
      );
      expect(find.text('পূর্বের ব্যাকআপ পাওয়া গেছে'), findsOneWidget);
      expect(find.text('শেষ ব্যাকআপ ৩০ দিন আগে'), findsNothing);
    });

    testWidgets('reminder alone shows', (tester) async {
      await _pump(tester, HomeScenario.populated(reminder: reminder));
      expect(find.text('শেষ ব্যাকআপ ৩০ দিন আগে'), findsOneWidget);
      expect(find.text('পূর্বের ব্যাকআপ পাওয়া গেছে'), findsNothing);
    });

    testWidgets('neither -> nothing', (tester) async {
      await _pump(tester, HomeScenario.populated());
      expect(find.text('পূর্বের ব্যাকআপ পাওয়া গেছে'), findsNothing);
      expect(find.textContaining('শেষ ব্যাকআপ'), findsNothing);
    });
  });

  group('empty = zero expenses AND zero income', () {
    testWidgets('welcome hero, three steps, primary action, SMS teaser', (
      tester,
    ) async {
      await _pump(tester, HomeScenario.empty());
      expect(find.text('PocketPilot-এ স্বাগতম'), findsOneWidget);
      expect(find.textContaining('প্রথম খরচ যোগ করুন'), findsOneWidget);
      expect(find.textContaining('SMS থেকে লেনদেন আনুন'), findsOneWidget);
      expect(find.textContaining('ওয়ালেট সেট করুন'), findsOneWidget);
      expect(find.text('খরচ যোগ করুন'), findsWidgets);
      expect(find.text('SMS থেকে নিজে নিজে লেনদেন যোগ করুন'), findsOneWidget);
      expect(find.text('মোট সম্পদ'), findsNothing);
      expect(find.text('এই মাসের খরচ'), findsNothing);
    });

    testWidgets('no SMS teaser once SMS import is on', (tester) async {
      await _pump(tester, HomeScenario.empty(smsEnabled: true));
      expect(find.byType(HomeSmsTeaser), findsOneWidget);
      expect(find.text('SMS থেকে নিজে নিজে লেনদেন যোগ করুন'), findsNothing);
    });

    testWidgets('a found backup is still offered on a fresh install', (
      tester,
    ) async {
      await _pump(tester, HomeScenario.empty(restoreBackup: _backupInfo));
      expect(find.text('পূর্বের ব্যাকআপ পাওয়া গেছে'), findsOneWidget);
      expect(find.text('PocketPilot-এ স্বাগতম'), findsOneWidget);
    });

    testWidgets('one income and no expenses is NOT empty', (tester) async {
      final base = HomeScenario.populated();
      await _pump(
        tester,
        HomeScenario(wallets: base.wallets, incomes: base.incomes),
      );
      expect(find.text('PocketPilot-এ স্বাগতম'), findsNothing);
      expect(find.text('মোট সম্পদ'), findsOneWidget);
      expect(find.text('অক্টোবরের বেতন'), findsOneWidget);
    });
  });

  group('dark', () {
    testWidgets('populated renders without layout errors', (tester) async {
      await _pump(
        tester,
        HomeScenario.populated(),
        brightness: Brightness.dark,
      );
      expect(find.text('মোট সম্পদ'), findsOneWidget);
    });

    testWidgets('empty renders without layout errors', (tester) async {
      await _pump(tester, HomeScenario.empty(), brightness: Brightness.dark);
      expect(find.text('PocketPilot-এ স্বাগতম'), findsOneWidget);
    });
  });

  // Review aid, not an assertion: `R1_PREVIEW=1 flutter test <this file>` renders
  // the three Home states to build/r1_preview/*.png (git-ignored) with the real
  // fonts, at 360x800 logical (saved at 2x = 720x1600) and full length.
  final preview = Platform.environment['R1_PREVIEW'] == '1';
  group('preview PNGs', skip: preview ? false : 'set R1_PREVIEW=1', () {
    final states = <String, (HomeScenario, Brightness)>{
      'home_populated': (HomeScenario.populated(), Brightness.light),
      'home_empty': (HomeScenario.empty(), Brightness.light),
      'home_dark': (HomeScenario.populated(), Brightness.dark),
    };
    for (final entry in states.entries) {
      for (final full in [false, true]) {
        testWidgets('${entry.key}${full ? '_full' : ''}', (tester) async {
          final key = GlobalKey();
          tester.view.physicalSize = Size(1080, full ? 4800 : 2400);
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            RepaintBoundary(
              key: key,
              child: homeApp(entry.value.$1, brightness: entry.value.$2),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          await tester.runAsync(() async {
            final boundary =
                key.currentContext!.findRenderObject() as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final dir = Directory('build/r1_preview')
              ..createSync(recursive: true);
            File(
              '${dir.path}/${entry.key}${full ? '_full' : ''}.png',
            ).writeAsBytesSync(bytes!.buffer.asUint8List());
          });
        });
      }
    }
  });
}

extension on CommonFinders {
  /// First Text whose data starts with [prefix] (greeting has one of 4 forms).
  Finder textMatching(String prefix) => find.byWidgetPredicate(
    (widget) => widget is Text && (widget.data ?? '').startsWith(prefix),
  );
}
