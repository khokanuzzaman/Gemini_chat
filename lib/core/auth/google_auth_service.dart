import 'package:google_sign_in/google_sign_in.dart';

import 'google_auth_models.dart';

abstract class GoogleAuthService {
  Future<GoogleAuthSession?> restoreSession();

  Future<GoogleAuthSession?> signIn();

  Future<void> signOut();

  Future<void> disconnect();

  Future<GoogleAuthTokens?> getTokens();

  Future<Map<String, String>?> getAuthHeaders();
}

class GoogleSignInAuthService implements GoogleAuthService {
  GoogleSignInAuthService({required GoogleSignIn googleSignIn})
    : _googleSignIn = googleSignIn;

  final GoogleSignIn _googleSignIn;

  @override
  Future<GoogleAuthSession?> restoreSession() async {
    final account = await _googleSignIn.signInSilently(suppressErrors: true);
    return _toSession(account);
  }

  @override
  Future<GoogleAuthSession?> signIn() async {
    final account = await _googleSignIn.signIn();
    return _toSession(account);
  }

  @override
  Future<void> signOut() {
    return _googleSignIn.signOut();
  }

  @override
  Future<void> disconnect() {
    return _googleSignIn.disconnect();
  }

  @override
  Future<GoogleAuthTokens?> getTokens() async {
    final user =
        _googleSignIn.currentUser ??
        await _googleSignIn.signInSilently(suppressErrors: true);
    if (user == null) {
      return null;
    }
    final auth = await user.authentication;
    return GoogleAuthTokens(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
      serverAuthCode: user.serverAuthCode,
    );
  }

  @override
  Future<Map<String, String>?> getAuthHeaders() async {
    final user = _googleSignIn.currentUser;
    if (user != null) {
      return user.authHeaders;
    }
    final restored = await _googleSignIn.signInSilently(suppressErrors: true);
    if (restored == null) {
      return null;
    }
    return restored.authHeaders;
  }

  GoogleAuthSession? _toSession(GoogleSignInAccount? account) {
    if (account == null) {
      return null;
    }

    return GoogleAuthSession(
      id: account.id,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
      serverAuthCode: account.serverAuthCode,
    );
  }
}
