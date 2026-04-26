import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

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

  Future<http.Client?> getDriveHttpClient() async {
    if (_googleSignIn.currentUser == null) {
      await _googleSignIn.signInSilently(suppressErrors: true);
    }
    await _ensureDriveScopes();
    return _googleSignIn.authenticatedClient();
  }

  String? get userId => _firebaseAuth.currentUser?.uid;

  String? get userEmail => _firebaseAuth.currentUser?.email;

  String? get displayName => _firebaseAuth.currentUser?.displayName;

  Future<void> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently(suppressErrors: true);
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
