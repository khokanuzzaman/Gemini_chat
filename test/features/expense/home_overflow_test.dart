import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/core/backup/backup_models.dart';
import 'package:gemini_chat/core/backup/backup_reminder_policy.dart';

import '../../helpers/app_fonts.dart';
import '../../helpers/home_harness.dart';

/// R1: every Home state, light + dark, at the narrowest (320dp) and common-small
/// (360dp) phone widths, at normal and 1.3x system text — with the REAL fonts.
/// A Flutter overflow is a thrown exception, so `takeException()` is the assertion.
void main() {
  setUpAll(() async {
    await loadAppFonts();
    await initializeDateFormatting('bn');
  });

  final backup = BackupFileInfo(
    fileId: 'f',
    name: 'b.enc',
    sizeBytes: 4096,
    modifiedAt: DateTime(2026, 10, 1),
  );
  const reminder = BackupReminderDecision(show: true, daysSinceBackup: 30);

  // Worst case for width: huge balances, long names.
  final stress = HomeScenario.populated();

  final scenarios = <String, HomeScenario>{
    'populated + SMS pending': HomeScenario.populated(),
    'populated + backup reminder': HomeScenario.populated(reminder: reminder),
    'populated + restore banner': HomeScenario.populated(restoreBackup: backup),
    'populated, signed out, no SMS pending': HomeScenario.populated(
      name: null,
      smsPending: 0,
    ),
    'populated, many alerts': stress,
    'empty': HomeScenario.empty(),
    'empty + restore banner': HomeScenario.empty(restoreBackup: backup),
  };

  for (final brightness in [Brightness.light, Brightness.dark]) {
    for (final width in [320.0, 360.0]) {
      for (final scale in [1.0, 1.3]) {
        for (final entry in scenarios.entries) {
          testWidgets(
            '${entry.key} — ${brightness.name}, ${width.toInt()}dp, ×$scale',
            (tester) async {
              tester.view.physicalSize = Size(width, 800);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.reset);
              await tester.pumpWidget(
                homeApp(entry.value, brightness: brightness, textScale: scale),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
}
