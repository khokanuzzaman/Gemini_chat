/// Deleting the user's account and everything we hold for it.
///
/// Pure orchestration over injected steps, so the ORDER and the failure handling
/// are unit-tested with fakes (no Firebase in the test). The order is chosen so a
/// failure never strands the user:
///
///   1. Drive backups (optional) — needs the Google session, so it goes first;
///      a failure here changes nothing irreversible.
///   2. Firestore docs under `users/{uid}` — needs the signed-in user.
///   3. The Firebase Auth user — if Firebase says the sign-in is too old, the user
///      re-authenticates with Google and this step is retried once.
///   4. Sign out, then the local wipe ("সব ডেটা মুছুন").
///
/// Nothing local is wiped until every cloud step succeeded: a failure leaves the
/// device exactly as it was, so the user can simply try again (every step is
/// idempotent).
class AccountDeletionService {
  AccountDeletionService({
    required this.currentUid,
    required this.deleteDriveBackups,
    required this.deleteUserDocs,
    required this.deleteAuthUser,
    required this.reauthenticate,
    required this.signOut,
    required this.wipeLocal,
  });

  final String? Function() currentUid;
  final Future<void> Function() deleteDriveBackups;
  final Future<void> Function(String uid) deleteUserDocs;

  /// Throws [RequiresRecentLoginException] when Firebase wants a fresh sign-in.
  final Future<void> Function() deleteAuthUser;

  /// Re-signs in with Google. Throws [ReauthCancelledException] if the user backs
  /// out, [AccountDeletionException] on any other failure.
  final Future<void> Function() reauthenticate;
  final Future<void> Function() signOut;
  final Future<void> Function() wipeLocal;

  Future<AccountDeletionResult> delete({
    required bool deleteDriveBackup,
  }) async {
    final uid = currentUid();
    if (uid == null || uid.isEmpty) {
      return const AccountDeletionResult.failed(
        AccountDeletionStage.start,
        'সাইন ইন করা অ্যাকাউন্ট পাওয়া যায়নি',
      );
    }

    if (deleteDriveBackup) {
      final failure = await _guard(
        AccountDeletionStage.driveBackups,
        deleteDriveBackups,
      );
      if (failure != null) return failure;
    }

    final docs = await _guard(
      AccountDeletionStage.cloudData,
      () => deleteUserDocs(uid),
    );
    if (docs != null) return docs;

    final auth = await _deleteAuthUserWithReauth();
    if (auth != null) return auth;

    // The account is gone. A sign-out failure must not strand local data the user
    // asked to erase, so it is swallowed (the local wipe signs out as well).
    try {
      await signOut();
    } catch (_) {}

    final wipe = await _guard(AccountDeletionStage.localData, wipeLocal);
    if (wipe != null) return wipe;

    return const AccountDeletionResult.success();
  }

  Future<AccountDeletionResult?> _deleteAuthUserWithReauth() async {
    try {
      await deleteAuthUser();
      return null;
    } on RequiresRecentLoginException {
      // Fall through to re-authentication.
    } catch (error) {
      return AccountDeletionResult.failed(
        AccountDeletionStage.account,
        _messageFor(error),
      );
    }

    try {
      await reauthenticate();
    } on ReauthCancelledException {
      return const AccountDeletionResult.failed(
        AccountDeletionStage.reauthentication,
        'নিরাপত্তার জন্য আবার Google দিয়ে সাইন ইন করতে হবে। অ্যাকাউন্ট মোছা হয়নি।',
        cancelled: true,
      );
    } catch (error) {
      return AccountDeletionResult.failed(
        AccountDeletionStage.reauthentication,
        _messageFor(error),
      );
    }

    try {
      await deleteAuthUser();
      return null;
    } catch (error) {
      return AccountDeletionResult.failed(
        AccountDeletionStage.account,
        _messageFor(error),
      );
    }
  }

  Future<AccountDeletionResult?> _guard(
    AccountDeletionStage stage,
    Future<void> Function() step,
  ) async {
    try {
      await step();
      return null;
    } catch (error) {
      return AccountDeletionResult.failed(stage, _messageFor(error));
    }
  }

  static String _messageFor(Object error) {
    if (error is AccountDeletionException) return error.message;
    return 'অ্যাকাউন্ট মোছা যায়নি। ইন্টারনেট সংযোগ দেখে আবার চেষ্টা করুন।';
  }
}

enum AccountDeletionStage {
  start,
  driveBackups,
  cloudData,
  reauthentication,
  account,
  localData,
}

class AccountDeletionResult {
  const AccountDeletionResult.success()
    : isSuccess = true,
      failedAt = null,
      message = null,
      cancelled = false;

  const AccountDeletionResult.failed(
    AccountDeletionStage stage,
    String this.message, {
    this.cancelled = false,
  }) : isSuccess = false,
       failedAt = stage;

  final bool isSuccess;
  final AccountDeletionStage? failedAt;
  final String? message;

  /// The user declined the re-authentication prompt (not an error as such).
  final bool cancelled;
}

class AccountDeletionException implements Exception {
  const AccountDeletionException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Firebase refuses to delete a user whose last sign-in is too old.
class RequiresRecentLoginException extends AccountDeletionException {
  const RequiresRecentLoginException()
    : super('সাইন ইনের সময় পেরিয়ে গেছে, আবার সাইন ইন করুন');
}

class ReauthCancelledException extends AccountDeletionException {
  const ReauthCancelledException() : super('সাইন ইন বাতিল করা হয়েছে');
}
