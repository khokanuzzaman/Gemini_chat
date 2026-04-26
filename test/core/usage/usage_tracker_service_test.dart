import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gemini_chat/core/usage/usage_limits.dart';
import 'package:gemini_chat/core/usage/usage_status.dart';
import 'package:gemini_chat/core/usage/usage_tracker_service.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  group('UsageStatus', () {
    test('reports near limit at eighty percent', () {
      final status = UsageStatus(
        feature: UsageLimits.aiChat,
        used: 16,
        limit: UsageLimits.aiChatPerDay,
        isMonthly: false,
        resetAt: DateTime(2026, 4, 30),
      );

      expect(status.isNearLimit, isTrue);
      expect(status.hasReachedLimit, isFalse);
      expect(status.remaining, 4);
      expect(status.resetAtBengali, 'আজ রাত ১২টায়');
    });
  });

  group('UsageTrackerService', () {
    late SharedPreferences prefs;
    late _MockFirebaseAuth firebaseAuth;
    late FakeFirebaseFirestore firestore;
    late UsageTrackerService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      firebaseAuth = _MockFirebaseAuth();
      firestore = FakeFirebaseFirestore();
      service = UsageTrackerService(
        firebaseAuth: firebaseAuth,
        firestore: firestore,
        prefs: prefs,
      );
    });

    test('returns zero initially when signed out', () async {
      when(() => firebaseAuth.currentUser).thenReturn(null);

      final count = await service.getCount(UsageLimits.aiChat);

      expect(count, 0);
    });

    test('blocks the twenty first daily AI chat consume', () async {
      when(() => firebaseAuth.currentUser).thenReturn(null);

      for (var index = 0; index < UsageLimits.aiChatPerDay; index++) {
        final result = await service.checkAndConsume(UsageLimits.aiChat);
        expect(result.isAllowed, isTrue);
      }

      final blocked = await service.checkAndConsume(UsageLimits.aiChat);

      expect(blocked.isAllowed, isFalse);
      expect(blocked.status.used, UsageLimits.aiChatPerDay);
      expect(blocked.status.hasReachedLimit, isTrue);
    });

    test('returns all five feature statuses', () async {
      when(() => firebaseAuth.currentUser).thenReturn(null);

      final statuses = await service.getAllStatuses();

      expect(statuses.keys, UsageLimits.allFeatures);
      expect(statuses[UsageLimits.cloudBackup]?.limit, 1);
      expect(statuses[UsageLimits.aiBudget]?.isMonthly, isTrue);
    });

    test('syncs firestore counters into local storage', () async {
      final user = _MockUser();
      final dailyKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final monthlyKey = DateFormat('yyyy-MM').format(DateTime.now());

      when(() => firebaseAuth.currentUser).thenReturn(user);
      when(() => user.uid).thenReturn('uid_123');
      await firestore.doc('users/uid_123/usage/$dailyKey').set({
        UsageLimits.aiChat: 7,
        UsageLimits.receiptScan: 2,
        UsageLimits.voiceInput: 4,
        UsageLimits.cloudBackup: 1,
      });
      await firestore.doc('users/uid_123/usage/$monthlyKey').set({
        UsageLimits.aiBudget: 3,
      });

      await service.syncFromFirestore();

      expect(prefs.getInt('usage_ai_chat_$dailyKey'), 7);
      expect(prefs.getInt('usage_receipt_scan_$dailyKey'), 2);
      expect(prefs.getInt('usage_voice_input_$dailyKey'), 4);
      expect(prefs.getInt('usage_cloud_backup_$dailyKey'), 1);
      expect(prefs.getInt('usage_ai_budget_$monthlyKey'), 3);
    });
  });
}
