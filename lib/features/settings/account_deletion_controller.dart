import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/account_deletion_service.dart';
import '../../core/auth/user_cloud_data.dart';
import '../../core/backup/backup_providers.dart';
import 'local_data_wipe.dart';

/// Wires [AccountDeletionService] to the real Google/Firebase/Drive/Isar pieces.
AccountDeletionService buildAccountDeletionService(WidgetRef ref) {
  final auth = ref.read(googleAuthServiceProvider);
  final backups = ref.read(backupStateProvider.notifier);
  return AccountDeletionService(
    currentUid: () => auth.userId,
    deleteDriveBackups: () async {
      if (!await backups.deleteAllBackups()) {
        throw const AccountDeletionException(
          'Google Drive-এর ব্যাকআপ মোছা যায়নি। আবার চেষ্টা করুন, অথবা ব্যাকআপ না মুছে এগোন।',
        );
      }
    },
    deleteUserDocs: (uid) async {
      try {
        await UserCloudData(FirebaseFirestore.instance).deleteAll(uid);
      } on FirebaseException catch (error) {
        throw AccountDeletionException(
          error.code == 'unavailable'
              ? 'ইন্টারনেট সংযোগ নেই। সংযোগ দেখে আবার চেষ্টা করুন।'
              : 'ক্লাউড ডেটা মোছা যায়নি। একটু পরে আবার চেষ্টা করুন।',
        );
      }
    },
    deleteAuthUser: auth.deleteCurrentUser,
    reauthenticate: auth.reauthenticate,
    signOut: backups.signOut,
    wipeLocal: () => wipeAllLocalData(ref),
  );
}
