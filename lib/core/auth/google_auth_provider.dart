import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import '../providers/shared_preferences_provider.dart';
import 'google_auth_models.dart';
import 'google_auth_service.dart';

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  final configuredClientId = _resolveServerClientId();
  final googleSignIn = GoogleSignIn(
    scopes: const [drive.DriveApi.driveAppdataScope],
    serverClientId: configuredClientId,
  );
  return GoogleSignInAuthService(googleSignIn: googleSignIn);
});

final googleAuthProvider =
    NotifierProvider<GoogleAuthNotifier, GoogleAuthState>(
      GoogleAuthNotifier.new,
    );

class GoogleAuthNotifier extends Notifier<GoogleAuthState> {
  static const _isSignedInKey = 'google_auth_is_signed_in';
  static const _userIdKey = 'google_auth_user_id';
  static const _emailKey = 'google_auth_email';
  static const _displayNameKey = 'google_auth_display_name';
  static const _photoUrlKey = 'google_auth_photo_url';
  static const _serverAuthCodeKey = 'google_auth_server_auth_code';

  @override
  GoogleAuthState build() {
    final persistedSession = _readPersistedSession();
    Future<void>.microtask(_restoreSession);
    return GoogleAuthState.initial(session: persistedSession);
  }

  Future<bool> signIn() async {
    state = state.copyWith(isBusy: true, errorMessage: null);
    try {
      final session = await ref.read(googleAuthServiceProvider).signIn();
      if (session == null) {
        state = state.copyWith(isBusy: false);
        return false;
      }
      await _persistSession(session);
      state = state.copyWith(
        isLoading: false,
        isBusy: false,
        session: session,
        errorMessage: null,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isBusy: false,
        errorMessage: _friendlyError(error),
      );
      return false;
    }
  }

  Future<void> signOut({bool revokeAccess = false}) async {
    state = state.copyWith(isBusy: true, errorMessage: null);
    try {
      if (revokeAccess) {
        await ref.read(googleAuthServiceProvider).disconnect();
      } else {
        await ref.read(googleAuthServiceProvider).signOut();
      }
    } catch (_) {}

    await clearStoredState();
    state = state.copyWith(
      isLoading: false,
      isBusy: false,
      session: null,
      errorMessage: null,
    );
  }

  Future<void> clearStoredState() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_isSignedInKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_displayNameKey);
    await prefs.remove(_photoUrlKey);
    await prefs.remove(_serverAuthCodeKey);
  }

  Future<GoogleAuthTokens?> getTokens() {
    return ref.read(googleAuthServiceProvider).getTokens();
  }

  Future<Map<String, String>?> getAuthHeaders() {
    return ref.read(googleAuthServiceProvider).getAuthHeaders();
  }

  Future<void> _restoreSession() async {
    try {
      final session = await ref
          .read(googleAuthServiceProvider)
          .restoreSession();
      if (session == null) {
        await clearStoredState();
        state = state.copyWith(
          isLoading: false,
          isBusy: false,
          session: null,
          errorMessage: null,
        );
        return;
      }

      await _persistSession(session);
      state = state.copyWith(
        isLoading: false,
        isBusy: false,
        session: session,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isBusy: false,
        errorMessage: _friendlyError(error),
      );
    }
  }

  GoogleAuthSession? _readPersistedSession() {
    final prefs = ref.read(sharedPreferencesProvider);
    final isSignedIn = prefs.getBool(_isSignedInKey) ?? false;
    final userId = prefs.getString(_userIdKey);
    final email = prefs.getString(_emailKey);
    if (!isSignedIn ||
        userId == null ||
        userId.isEmpty ||
        email == null ||
        email.isEmpty) {
      return null;
    }

    return GoogleAuthSession(
      id: userId,
      email: email,
      displayName: prefs.getString(_displayNameKey),
      photoUrl: prefs.getString(_photoUrlKey),
      serverAuthCode: prefs.getString(_serverAuthCodeKey),
    );
  }

  Future<void> _persistSession(GoogleAuthSession session) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_isSignedInKey, true);
    await prefs.setString(_userIdKey, session.id);
    await prefs.setString(_emailKey, session.email);
    if (session.displayName == null || session.displayName!.isEmpty) {
      await prefs.remove(_displayNameKey);
    } else {
      await prefs.setString(_displayNameKey, session.displayName!);
    }
    if (session.photoUrl == null || session.photoUrl!.isEmpty) {
      await prefs.remove(_photoUrlKey);
    } else {
      await prefs.setString(_photoUrlKey, session.photoUrl!);
    }
    if (session.serverAuthCode == null || session.serverAuthCode!.isEmpty) {
      await prefs.remove(_serverAuthCodeKey);
    } else {
      await prefs.setString(_serverAuthCodeKey, session.serverAuthCode!);
    }
  }

  String _friendlyError(Object error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('sign_in_failed') ||
        raw.contains('clientconfigurationerror') ||
        raw.contains('12500') ||
        raw.contains('10:')) {
      return 'Google Sign-In configure করা নেই। SHA-1, package name, আর google-services.json আবার check করুন।';
    }
    if (raw.contains('network')) {
      return 'নেটওয়ার্ক সমস্যা হয়েছে। আবার চেষ্টা করুন।';
    }
    return 'Google অ্যাকাউন্টে সাইন ইন করা যায়নি।';
  }
}

String? _resolveServerClientId() {
  const dartDefineValue = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  if (dartDefineValue.trim().isNotEmpty) {
    return dartDefineValue.trim();
  }

  final envValue = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
  if (envValue != null && envValue.trim().isNotEmpty) {
    return envValue.trim();
  }

  return null;
}
