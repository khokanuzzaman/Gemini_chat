import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gemini_chat/core/auth/google_auth_models.dart';
import 'package:gemini_chat/core/auth/google_auth_provider.dart';
import 'package:gemini_chat/core/auth/google_auth_service.dart';
import 'package:gemini_chat/core/providers/shared_preferences_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoogleAuthNotifier', () {
    test('loads persisted session immediately', () async {
      SharedPreferences.setMockInitialValues({
        'google_auth_is_signed_in': true,
        'google_auth_user_id': 'persisted-id',
        'google_auth_email': 'persisted@example.com',
        'google_auth_display_name': 'Persisted User',
      });
      final prefs = await SharedPreferences.getInstance();
      final service = _FakeGoogleAuthService();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          googleAuthServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final immediateState = container.read(googleAuthProvider);
      expect(immediateState.isSignedIn, isTrue);
      expect(immediateState.session?.email, 'persisted@example.com');

      await Future<void>.delayed(const Duration(milliseconds: 1));
      final settledState = container.read(googleAuthProvider);
      expect(service.restoreCalls, 1);
      expect(settledState.isSignedIn, isFalse);
    });

    test('signIn persists account and signOut clears it', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = _FakeGoogleAuthService()
        ..nextSession = const GoogleAuthSession(
          id: 'user-1',
          email: 'user@example.com',
          displayName: 'User One',
          serverAuthCode: 'server-code',
        )
        ..restoreResult = const GoogleAuthSession(
          id: 'user-1',
          email: 'user@example.com',
          displayName: 'User One',
          serverAuthCode: 'server-code',
        );
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          googleAuthServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(googleAuthProvider.notifier);
      final signedIn = await notifier.signIn();
      expect(signedIn, isTrue);
      expect(
        container.read(googleAuthProvider).session?.email,
        'user@example.com',
      );
      expect(prefs.getBool('google_auth_is_signed_in'), isTrue);
      expect(prefs.getString('google_auth_email'), 'user@example.com');

      await notifier.signOut(revokeAccess: true);
      expect(service.disconnectCalls, 1);
      expect(container.read(googleAuthProvider).isSignedIn, isFalse);
      expect(prefs.getBool('google_auth_is_signed_in'), isNull);
      expect(prefs.getString('google_auth_email'), isNull);
    });
  });
}

class _FakeGoogleAuthService implements GoogleAuthService {
  GoogleAuthSession? nextSession;
  GoogleAuthSession? restoreResult;
  int restoreCalls = 0;
  int signInCalls = 0;
  int signOutCalls = 0;
  int disconnectCalls = 0;

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
  }

  @override
  Future<Map<String, String>?> getAuthHeaders() async => null;

  @override
  Future<GoogleAuthTokens?> getTokens() async => null;

  @override
  Future<GoogleAuthSession?> restoreSession() async {
    restoreCalls++;
    return restoreResult;
  }

  @override
  Future<GoogleAuthSession?> signIn() async {
    signInCalls++;
    return nextSession;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}
