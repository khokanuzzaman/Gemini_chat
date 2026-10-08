import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../auth/account_deletion_service.dart';
import 'backup_exception.dart';

class GoogleAuthService {
  static const _driveScopes = <String>[
    'email',
    drive.DriveApi.driveAppdataScope,
  ];

  GoogleAuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn =
          googleSignIn ??
          GoogleSignIn(
            scopes: _driveScopes,
            serverClientId: _resolveServerClientId(),
          );

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  Future<bool> isSignedIn() async {
    return _firebaseAuth.currentUser != null;
  }

  Future<bool> signIn() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      return false;
    }
    await _ensureDriveScopes();

    final authentication = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: authentication.accessToken,
      idToken: authentication.idToken,
    );
    await _firebaseAuth.signInWithCredential(credential);
    return true;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }

  /// Deletes the Firebase Auth user. Maps "sign-in too old" to
  /// [RequiresRecentLoginException] so the caller can re-authenticate and retry.
  Future<void> deleteCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return;
    }
    try {
      await user.delete();
    } on FirebaseAuthException catch (error) {
      if (error.code == 'requires-recent-login') {
        throw const RequiresRecentLoginException();
      }
      if (error.code == 'network-request-failed') {
        throw const AccountDeletionException(
          'ইন্টারনেট সংযোগ নেই। সংযোগ দেখে আবার চেষ্টা করুন।',
        );
      }
      rethrow;
    }
  }

  /// Interactive Google sign-in for the CURRENT Firebase user (account deletion's
  /// "recent login"). Throws [ReauthCancelledException] if the user backs out.
  Future<void> reauthenticate() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return;
    }
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw const ReauthCancelledException();
    }
    final authentication = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: authentication.accessToken,
      idToken: authentication.idToken,
    );
    try {
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'user-mismatch' || error.code == 'wrong-password') {
        throw const AccountDeletionException(
          'যে Google অ্যাকাউন্টে সাইন ইন করা আছে, সেটিই ব্যবহার করুন।',
        );
      }
      rethrow;
    }
  }

  Future<http.Client?> getDriveHttpClient() async {
    if (_googleSignIn.currentUser == null) {
      await _silentAccount();
    }
    await _ensureDriveScopes();
    return _googleSignIn.authenticatedClient();
  }

  String? get userId => _firebaseAuth.currentUser?.uid;

  String? get userEmail => _firebaseAuth.currentUser?.email;

  String? get displayName => _firebaseAuth.currentUser?.displayName;

  /// The plugin allows ONE silent sign-in at a time and rejects the second with
  /// "Concurrent operations detected" (seen in logcat at app start, where Home,
  /// the backup notifier and the auto-backup guard all ask at once). Callers that
  /// arrive while one is running share it.
  Future<void>? _silentSignInInFlight;
  Future<GoogleSignInAccount?>? _silentAccountInFlight;

  Future<GoogleSignInAccount?> _silentAccount() {
    return _silentAccountInFlight ??= _googleSignIn
        .signInSilently(suppressErrors: true)
        .whenComplete(() => _silentAccountInFlight = null);
  }

  Future<void> signInSilently() {
    return _silentSignInInFlight ??= _signInSilentlyOnce().whenComplete(
      () => _silentSignInInFlight = null,
    );
  }

  Future<void> _signInSilentlyOnce() async {
    try {
      final account = await _silentAccount();
      if (account == null) {
        return;
      }
      await _ensureDriveScopes(requestIfMissing: false);
      final authentication = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: authentication.accessToken,
        idToken: authentication.idToken,
      );
      await _firebaseAuth.signInWithCredential(credential);
    } catch (_) {
      // Silent auth is best-effort.
    }
  }

  Future<void> _ensureDriveScopes({bool requestIfMissing = true}) async {
    if (_googleSignIn.currentUser == null) {
      return;
    }

    bool hasScopes;
    try {
      hasScopes = await _googleSignIn.canAccessScopes(_driveScopes);
    } on UnimplementedError {
      // Some resolved platform implementations do not expose this API yet.
      return;
    }
    if (hasScopes) {
      return;
    }
    if (!requestIfMissing) {
      return;
    }

    final granted = await _googleSignIn.requestScopes(_driveScopes);
    if (!granted) {
      throw const BackupException(
        'Google Drive অনুমতি মেলেনি। আবার Google দিয়ে সাইন ইন করুন।',
        code: BackupErrorCode.auth,
      );
    }
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
