import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gemini_chat/core/backup/google_auth_service.dart';

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  test('simultaneous silent sign-ins share ONE plugin call', () async {
    final google = _MockGoogleSignIn();
    final gate = Completer<GoogleSignInAccount?>();
    when(
      () => google.signInSilently(suppressErrors: true),
    ).thenAnswer((_) => gate.future);
    final service = GoogleAuthService(
      firebaseAuth: _MockFirebaseAuth(),
      googleSignIn: google,
    );

    // Home, the backup notifier and the auto-backup guard all ask at start-up.
    final calls = [
      service.signInSilently(),
      service.signInSilently(),
      service.signInSilently(),
    ];
    gate.complete(null);
    await Future.wait(calls);

    verify(() => google.signInSilently(suppressErrors: true)).called(1);
  });

  test(
    'a later silent sign-in runs again once the first has finished',
    () async {
      final google = _MockGoogleSignIn();
      when(
        () => google.signInSilently(suppressErrors: true),
      ).thenAnswer((_) async => null);
      final service = GoogleAuthService(
        firebaseAuth: _MockFirebaseAuth(),
        googleSignIn: google,
      );

      await service.signInSilently();
      await service.signInSilently();

      verify(() => google.signInSilently(suppressErrors: true)).called(2);
    },
  );
}
