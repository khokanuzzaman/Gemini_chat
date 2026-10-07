// "অ্যাকাউন্ট মুছুন": the ORDER and the failure handling, with fakes. The promise:
// nothing local is erased until every cloud step succeeded, and a failure always
// leaves the user able to try again.

import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/core/auth/account_deletion_service.dart';

class _Run {
  final log = <String>[];
  String? uid = 'user-1';
  Object? driveError;
  Object? docsError;
  Object? signOutError;
  Object? wipeError;
  Object? reauthError;

  /// What each successive deleteAuthUser() call throws (null = succeeds).
  final authErrors = <Object?>[];
  int authCalls = 0;

  AccountDeletionService build() => AccountDeletionService(
    currentUid: () => uid,
    deleteDriveBackups: () async {
      log.add('drive');
      if (driveError != null) throw driveError!;
    },
    deleteUserDocs: (u) async {
      log.add('docs:$u');
      if (docsError != null) throw docsError!;
    },
    deleteAuthUser: () async {
      log.add('auth');
      final error = authCalls < authErrors.length
          ? authErrors[authCalls]
          : null;
      authCalls++;
      if (error != null) throw error;
    },
    reauthenticate: () async {
      log.add('reauth');
      if (reauthError != null) throw reauthError!;
    },
    signOut: () async {
      log.add('signOut');
      if (signOutError != null) throw signOutError!;
    },
    wipeLocal: () async {
      log.add('wipe');
      if (wipeError != null) throw wipeError!;
    },
  );
}

void main() {
  test(
    'happy path with the Drive checkbox: drive → docs → auth → signOut → wipe',
    () async {
      final run = _Run();
      final result = await run.build().delete(deleteDriveBackup: true);
      expect(result.isSuccess, isTrue);
      expect(run.log, ['drive', 'docs:user-1', 'auth', 'signOut', 'wipe']);
    },
  );

  test('Drive checkbox OFF: backups are not touched', () async {
    final run = _Run();
    final result = await run.build().delete(deleteDriveBackup: false);
    expect(result.isSuccess, isTrue);
    expect(run.log, ['docs:user-1', 'auth', 'signOut', 'wipe']);
  });

  test(
    'requires-recent-login: re-authenticates, retries once, then succeeds',
    () async {
      final run = _Run()..authErrors.add(const RequiresRecentLoginException());
      final result = await run.build().delete(deleteDriveBackup: false);
      expect(result.isSuccess, isTrue);
      expect(run.log, [
        'docs:user-1',
        'auth', // refused: sign-in too old
        'reauth',
        'auth', // retried
        'signOut',
        'wipe',
      ]);
    },
  );

  test(
    're-auth cancelled: nothing local is wiped, user is told, can retry',
    () async {
      final run = _Run()
        ..authErrors.add(const RequiresRecentLoginException())
        ..reauthError = const ReauthCancelledException();
      final result = await run.build().delete(deleteDriveBackup: false);
      expect(result.isSuccess, isFalse);
      expect(result.cancelled, isTrue);
      expect(result.failedAt, AccountDeletionStage.reauthentication);
      expect(run.log, ['docs:user-1', 'auth', 'reauth']);
      expect(run.log, isNot(contains('wipe')));
      expect(run.log, isNot(contains('signOut')));
    },
  );

  test(
    'still refused after re-auth: fails at the account step, no wipe',
    () async {
      final run = _Run()
        ..authErrors.addAll(const [
          RequiresRecentLoginException(),
          RequiresRecentLoginException(),
        ]);
      final result = await run.build().delete(deleteDriveBackup: false);
      expect(result.isSuccess, isFalse);
      expect(result.failedAt, AccountDeletionStage.account);
      expect(run.log, ['docs:user-1', 'auth', 'reauth', 'auth']);
    },
  );

  test('re-auth failure (wrong account) is reported, no wipe', () async {
    final run = _Run()
      ..authErrors.add(const RequiresRecentLoginException())
      ..reauthError = const AccountDeletionException(
        'একই অ্যাকাউন্ট ব্যবহার করুন',
      );
    final result = await run.build().delete(deleteDriveBackup: false);
    expect(result.failedAt, AccountDeletionStage.reauthentication);
    expect(result.message, 'একই অ্যাকাউন্ট ব্যবহার করুন');
    expect(run.log, isNot(contains('wipe')));
  });

  test(
    'Firestore failure: the Auth user is NOT deleted, nothing wiped',
    () async {
      final run = _Run()
        ..docsError = const AccountDeletionException('ইন্টারনেট সংযোগ নেই');
      final result = await run.build().delete(deleteDriveBackup: true);
      expect(result.isSuccess, isFalse);
      expect(result.failedAt, AccountDeletionStage.cloudData);
      expect(result.message, 'ইন্টারনেট সংযোগ নেই');
      expect(run.log, ['drive', 'docs:user-1']);
    },
  );

  test('Drive failure stops before anything irreversible', () async {
    final run = _Run()..driveError = const AccountDeletionException('drive');
    final result = await run.build().delete(deleteDriveBackup: true);
    expect(result.failedAt, AccountDeletionStage.driveBackups);
    expect(run.log, ['drive']);
  });

  test(
    'an unexpected error gets a friendly retry message, not a stack trace',
    () async {
      final run = _Run()..docsError = StateError('boom');
      final result = await run.build().delete(deleteDriveBackup: false);
      expect(result.isSuccess, isFalse);
      expect(result.message, contains('আবার চেষ্টা করুন'));
      expect(result.message, isNot(contains('boom')));
    },
  );

  test('not signed in: refuses, touches nothing', () async {
    final run = _Run()..uid = null;
    final result = await run.build().delete(deleteDriveBackup: true);
    expect(result.isSuccess, isFalse);
    expect(result.failedAt, AccountDeletionStage.start);
    expect(run.log, isEmpty);
  });

  test('a failing sign-out does not strand the local wipe', () async {
    final run = _Run()..signOutError = StateError('x');
    final result = await run.build().delete(deleteDriveBackup: false);
    expect(result.isSuccess, isTrue);
    expect(run.log, ['docs:user-1', 'auth', 'signOut', 'wipe']);
  });

  test('a failing local wipe is reported (account is already gone)', () async {
    final run = _Run()..wipeError = StateError('disk');
    final result = await run.build().delete(deleteDriveBackup: false);
    expect(result.isSuccess, isFalse);
    expect(result.failedAt, AccountDeletionStage.localData);
  });

  test('retrying after a failure works (every step is idempotent)', () async {
    final run = _Run()..docsError = StateError('offline');
    final service = run.build();
    expect((await service.delete(deleteDriveBackup: false)).isSuccess, isFalse);
    run.docsError = null;
    run.log.clear();
    expect((await service.delete(deleteDriveBackup: false)).isSuccess, isTrue);
    expect(run.log, ['docs:user-1', 'auth', 'signOut', 'wipe']);
  });
}
