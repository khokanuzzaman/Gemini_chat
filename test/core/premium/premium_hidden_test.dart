// Phase 1 sells nothing: with PREMIUM_ENABLED off the Premium machinery is inert —
// RevenueCat is never configured, everyone is "free", there are no offerings, and
// there is no developer-facing warning text to leak into the UI.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gemini_chat/core/config/feature_flags.dart';
import 'package:gemini_chat/core/premium/premium_service.dart';

class _Auth extends Mock implements FirebaseAuth {}

PremiumService _service({required bool enabled}) => PremiumService(
  firebaseAuth: _Auth(),
  firestore: FakeFirebaseFirestore() as FirebaseFirestore,
  premiumEnabled: enabled,
);

void main() {
  setUp(() {
    // A perfectly valid production-looking key is present in both cases.
    dotenv.testLoad(
      fileInput: 'REVENUECAT_PUBLIC_SDK_KEY=goog_abcdefghijklmnop',
    );
  });

  test(
    'Premium is off by default (no --dart-define=PREMIUM_ENABLED)',
    () {
      expect(FeatureFlags.premiumEnabled, isFalse);
    },
    skip: FeatureFlags.premiumEnabled,
  );

  test('flag off: a valid key is ignored — not usable, no warning text', () {
    final service = _service(enabled: false);
    expect(service.hasUsableSdkKey, isFalse);
    expect(service.configurationWarningBn, isNull);
  });

  test('flag off: everyone is free and nothing is offered', () async {
    final service = _service(enabled: false);
    expect((await service.getStatus()).isPremium, isFalse);
    expect(await service.getOfferings(), isEmpty);
    expect(await service.isPremium(), isFalse);
  });

  test(
    'flag off: initialize() is a no-op (RevenueCat never configured)',
    () async {
      // Would hit the (absent) platform channel and log an error if it tried.
      await _service(enabled: false).initialize(userId: 'uid-1');
    },
  );

  test(
    'flag on: the same key IS usable (the switch is the only difference)',
    () {
      final service = _service(enabled: true);
      expect(service.hasUsableSdkKey, isTrue);
    },
  );
}
