import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/core/backup/backup_reminder_policy.dart';

final _now = DateTime(2026, 10, 6, 9);

BackupReminderInput _input({
  DateTime? lastBackup,
  DateTime? firstSeen,
  int records = 50,
  bool debtOrGoal = false,
  DateTime? snoozedUntil,
}) {
  return BackupReminderInput(
    now: _now,
    lastBackup: lastBackup,
    firstSeen: firstSeen,
    recordCount: records,
    hasDebtOrGoal: debtOrGoal,
    snoozedUntil: snoozedUntil,
  );
}

DateTime _ago(int days) => _now.subtract(Duration(days: days));

void main() {
  group('has a backup', () {
    test('29 days old -> hidden, 30 days old -> shown with the real age', () {
      expect(
        evaluateBackupReminder(
          _input(lastBackup: _ago(29), firstSeen: _ago(90)),
        ).show,
        isFalse,
      );
      final d = evaluateBackupReminder(
        _input(lastBackup: _ago(30), firstSeen: _ago(90)),
      );
      expect(d.show, isTrue);
      expect(d.daysSinceBackup, 30);
    });

    test(
      'a stale backup older than first-seen still counts (true age shown)',
      () {
        final d = evaluateBackupReminder(
          _input(lastBackup: _ago(100), firstSeen: _ago(1)),
        );
        expect(d.show, isTrue);
        expect(d.daysSinceBackup, 100);
      },
    );
  });

  group('never backed up', () {
    test('light user (<30 records): 30 days from first seen', () {
      expect(
        evaluateBackupReminder(_input(records: 12, firstSeen: _ago(29))).show,
        isFalse,
      );
      final d = evaluateBackupReminder(
        _input(records: 12, firstSeen: _ago(30)),
      );
      expect(d.show, isTrue);
      expect(
        d.daysSinceBackup,
        isNull,
        reason: 'never -> "এখনো কোনো ব্যাকআপ নেই"',
      );
    });

    test('heavy user (>=30 records): 7 days', () {
      expect(
        evaluateBackupReminder(_input(records: 30, firstSeen: _ago(6))).show,
        isFalse,
      );
      expect(
        evaluateBackupReminder(_input(records: 30, firstSeen: _ago(7))).show,
        isTrue,
      );
      expect(
        evaluateBackupReminder(_input(records: 29, firstSeen: _ago(7))).show,
        isFalse,
      );
    });

    test('unknown first-seen -> hidden (never guess)', () {
      expect(evaluateBackupReminder(_input()).show, isFalse);
    });
  });

  group('has data', () {
    test('under 10 records and no debt/goal -> hidden', () {
      expect(
        evaluateBackupReminder(_input(records: 9, firstSeen: _ago(400))).show,
        isFalse,
      );
      expect(
        evaluateBackupReminder(_input(records: 10, firstSeen: _ago(400))).show,
        isTrue,
      );
    });

    test('a debt or goal alone counts as data', () {
      expect(
        evaluateBackupReminder(
          _input(records: 0, debtOrGoal: true, firstSeen: _ago(40)),
        ).show,
        isTrue,
      );
    });
  });

  test('snooze hides it until the snooze ends', () {
    final snoozed = _now.add(const Duration(days: 3));
    expect(
      evaluateBackupReminder(
        _input(lastBackup: _ago(60), snoozedUntil: snoozed),
      ).show,
      isFalse,
    );
    expect(
      evaluateBackupReminder(
        _input(
          lastBackup: _ago(60),
          snoozedUntil: _now.subtract(const Duration(minutes: 1)),
        ),
      ).show,
      isTrue,
    );
  });
}
