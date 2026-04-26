import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gemini_chat/core/audio/voice_recorder_service.dart';
import 'package:gemini_chat/core/errors/failures.dart';
import 'package:gemini_chat/core/premium/premium_providers.dart';
import 'package:gemini_chat/core/premium/premium_service.dart';
import 'package:gemini_chat/core/scanner/receipt_scanner_service.dart';
import 'package:gemini_chat/core/scanner/scan_result.dart';
import 'package:gemini_chat/core/usage/usage_gate_result.dart';
import 'package:gemini_chat/core/usage/usage_limits.dart';
import 'package:gemini_chat/core/usage/usage_providers.dart';
import 'package:gemini_chat/core/usage/usage_status.dart';
import 'package:gemini_chat/core/usage/usage_tracker_service.dart';
import 'package:gemini_chat/core/utils/either.dart';
import 'package:gemini_chat/features/chat/domain/entities/message_entity.dart';
import 'package:gemini_chat/features/chat/domain/repositories/chat_repository.dart';
import 'package:gemini_chat/features/chat/presentation/providers/chat_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Chat usage gates', () {
    test('blocks AI chat and exposes limit status for free users', () async {
      final chatRepository = _FakeChatRepository();
      final usageService = _FakeUsageTrackerService(
        results: {
          UsageLimits.aiChat: UsageGateResult.blocked(
            UsageStatus(
              feature: UsageLimits.aiChat,
              used: 20,
              limit: 20,
              isMonthly: false,
              resetAt: DateTime(2026, 4, 30),
            ),
          ),
        },
      );
      final container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(chatRepository),
          usageTrackerServiceProvider.overrideWithValue(usageService),
          premiumServiceProvider.overrideWithValue(
            _FakePremiumService(isPremiumUser: false),
          ),
          isPremiumProvider.overrideWith((ref) => false),
        ],
      );
      addTearDown(container.dispose);

      await container.read(chatProvider.future);
      await container.read(chatProvider.notifier).sendMessage('আজকের খরচ কত?');

      expect(chatRepository.sendMessageCalls, 0);
      expect(
        container.read(limitReachedStatusProvider)?.feature,
        UsageLimits.aiChat,
      );
      expect(container.read(usageRefreshTokenProvider), 0);
    });

    test(
      'blocks voice input, stops recorder, and resets recording state',
      () async {
        final chatRepository = _FakeChatRepository();
        final voiceFile = File(
          '${Directory.systemTemp.path}/chat_voice_gate_test.m4a',
        );
        await voiceFile.writeAsBytes(const [1, 2, 3]);
        final recorder = _FakeVoiceRecorderService(voiceFile.path);
        final usageService = _FakeUsageTrackerService(
          results: {
            UsageLimits.voiceInput: UsageGateResult.blocked(
              UsageStatus(
                feature: UsageLimits.voiceInput,
                used: 10,
                limit: 10,
                isMonthly: false,
                resetAt: DateTime(2026, 4, 30),
              ),
            ),
          },
        );
        final container = ProviderContainer(
          overrides: [
            chatRepositoryProvider.overrideWithValue(chatRepository),
            voiceRecorderServiceProvider.overrideWithValue(recorder),
            usageTrackerServiceProvider.overrideWithValue(usageService),
            premiumServiceProvider.overrideWithValue(
              _FakePremiumService(isPremiumUser: false),
            ),
            isPremiumProvider.overrideWith((ref) => false),
          ],
        );
        addTearDown(container.dispose);

        await container.read(chatProvider.future);
        container.read(isRecordingProvider.notifier).state = true;
        container.read(recordingDurationProvider.notifier).state = '0:05';

        await container.read(chatProvider.notifier).stopAndSendVoice();

        expect(recorder.stopCalls, 1);
        expect(await voiceFile.exists(), isFalse);
        expect(container.read(isRecordingProvider), isFalse);
        expect(container.read(recordingDurationProvider), isNull);
        expect(chatRepository.sendVoiceCalls, 0);
        expect(
          container.read(limitReachedStatusProvider)?.feature,
          UsageLimits.voiceInput,
        );
      },
    );

    test('blocks receipt scanning before scanner runs', () async {
      final chatRepository = _FakeChatRepository();
      final scanner = _FakeReceiptScannerService();
      final usageService = _FakeUsageTrackerService(
        results: {
          UsageLimits.receiptScan: UsageGateResult.blocked(
            UsageStatus(
              feature: UsageLimits.receiptScan,
              used: 5,
              limit: 5,
              isMonthly: false,
              resetAt: DateTime(2026, 4, 30),
            ),
          ),
        },
      );
      final container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(chatRepository),
          receiptScannerServiceProvider.overrideWithValue(scanner),
          usageTrackerServiceProvider.overrideWithValue(usageService),
          premiumServiceProvider.overrideWithValue(
            _FakePremiumService(isPremiumUser: false),
          ),
          isPremiumProvider.overrideWith((ref) => false),
        ],
      );
      addTearDown(container.dispose);

      await container.read(chatProvider.future);
      await container.read(chatProvider.notifier).scanFromCamera();

      expect(scanner.cameraCalls, 0);
      expect(container.read(isScanningProvider), isFalse);
      expect(
        container.read(limitReachedStatusProvider)?.feature,
        UsageLimits.receiptScan,
      );
    });

    test('premium users bypass AI chat usage gate', () async {
      final chatRepository = _FakeChatRepository();
      final usageService = _FakeUsageTrackerService(
        results: {
          UsageLimits.aiChat: UsageGateResult.blocked(
            UsageStatus(
              feature: UsageLimits.aiChat,
              used: 20,
              limit: 20,
              isMonthly: false,
              resetAt: DateTime(2026, 4, 30),
            ),
          ),
        },
      );
      final container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(chatRepository),
          usageTrackerServiceProvider.overrideWithValue(usageService),
          premiumServiceProvider.overrideWithValue(
            _FakePremiumService(isPremiumUser: true),
          ),
          isPremiumProvider.overrideWith((ref) => true),
        ],
      );
      addTearDown(container.dispose);

      await container.read(chatProvider.future);
      container.read(ragEnabledProvider.notifier).state = false;

      await container.read(chatProvider.notifier).sendMessage('Premium test');

      expect(chatRepository.sendMessageCalls, 1);
      expect(usageService.checkCalls, isEmpty);
      expect(container.read(limitReachedStatusProvider), isNull);
    });
  });
}

class _FakeChatRepository implements ChatRepository {
  int sendMessageCalls = 0;
  int sendVoiceCalls = 0;
  int sendReceiptCalls = 0;
  final List<MessageEntity> _messages = [];

  @override
  Future<void> clearMessages() async {
    _messages.clear();
  }

  @override
  Future<List<MessageEntity>> loadMessages() async => List.of(_messages);

  @override
  Future<void> saveMessage(MessageEntity message) async {
    _messages.add(message);
  }

  @override
  Stream<Either<Failure, String>> sendMessage(
    List<MessageEntity> conversation, {
    bool useRag = true,
  }) async* {
    sendMessageCalls++;
    yield const Right('উত্তর');
  }

  @override
  Stream<Either<Failure, String>> sendReceiptText(String extractedText) async* {
    sendReceiptCalls++;
    yield const Right('রিসিট বিশ্লেষণ');
  }

  @override
  Stream<Either<Failure, String>> sendVoiceMessage(
    String audioFilePath, {
    bool useRag = true,
  }) async* {
    sendVoiceCalls++;
    yield const Right('ভয়েস উত্তর');
  }
}

class _FakeVoiceRecorderService implements VoiceRecorderService {
  _FakeVoiceRecorderService(this._audioPath);

  final String _audioPath;
  int stopCalls = 0;

  @override
  bool get isRecording => false;

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> startRecording() async {}

  @override
  Future<String?> stopRecording() async {
    stopCalls++;
    return _audioPath;
  }
}

class _FakeReceiptScannerService implements ReceiptScannerService {
  int cameraCalls = 0;
  int galleryCalls = 0;

  @override
  Future<ScanResult> pickAndScanFromCamera() async {
    cameraCalls++;
    return const ScanResult.failure('cancelled');
  }

  @override
  Future<ScanResult> pickAndScanFromGallery() async {
    galleryCalls++;
    return const ScanResult.failure('cancelled');
  }
}

class _FakeUsageTrackerService implements UsageTrackerService {
  _FakeUsageTrackerService({required this.results});

  final Map<String, UsageGateResult> results;
  final List<String> checkCalls = [];

  @override
  FirebaseAuth get firebaseAuth => throw UnimplementedError();

  @override
  FirebaseFirestore get firestore => throw UnimplementedError();

  @override
  SharedPreferences get prefs => throw UnimplementedError();

  @override
  Future<UsageGateResult> checkAndConsume(String feature) async {
    checkCalls.add(feature);
    return results[feature] ??
        UsageGateResult.allowed(
          UsageStatus(
            feature: feature,
            used: 1,
            limit: UsageLimits.limitFor(feature),
            isMonthly: UsageLimits.isMonthly(feature),
            resetAt: DateTime(2026, 4, 30),
          ),
        );
  }

  @override
  Future<Map<String, UsageStatus>> getAllStatuses() async => {
    for (final feature in UsageLimits.allFeatures)
      feature: UsageStatus(
        feature: feature,
        used: 0,
        limit: UsageLimits.limitFor(feature),
        isMonthly: UsageLimits.isMonthly(feature),
        resetAt: DateTime(2026, 4, 30),
      ),
  };

  @override
  Future<int> getCount(String feature) async => 0;

  @override
  Future<UsageStatus> getStatus(String feature) async => UsageStatus(
    feature: feature,
    used: 0,
    limit: UsageLimits.limitFor(feature),
    isMonthly: UsageLimits.isMonthly(feature),
    resetAt: DateTime(2026, 4, 30),
  );

  @override
  Future<bool> hasReachedLimit(String feature) async =>
      !(results[feature]?.isAllowed ?? true);

  @override
  Future<void> increment(String feature) async {}

  @override
  Future<void> syncFromFirestore() async {}
}

class _FakePremiumService implements PremiumService {
  _FakePremiumService({required this.isPremiumUser});

  final bool isPremiumUser;

  @override
  RevenueCatKeyMode get keyMode => RevenueCatKeyMode.production;

  @override
  bool get isUsingTestStore => false;

  @override
  bool get hasUsableSdkKey => true;

  @override
  String? get configurationWarningBn => null;

  @override
  void setMockPremium(bool enabled) {}

  @override
  Future<PremiumStatus> getStatus() async => isPremiumUser
      ? const PremiumStatus(isPremium: true, activeProductId: 'premium_monthly')
      : const PremiumStatus.free();

  @override
  Future<List<PremiumPackage>> getOfferings() async => const [];

  @override
  Future<void> initialize({String? userId}) async {}

  @override
  Future<bool> isPremium() async => isPremiumUser;

  @override
  Future<PurchaseResult> purchase(PremiumPackage package) async =>
      const PurchaseResult.error('unused');

  @override
  Future<PurchaseResult> restorePurchases() async =>
      const PurchaseResult.error('unused');

  @override
  Future<void> syncUserId(String? userId) async {}
}
