import 'package:cloud_firestore/cloud_firestore.dart';

/// What we keep in Firestore per user — and the one place that erases it.
///
/// `users/{uid}/usage/{period}`        feature counters (cloud_backup, AI limits)
/// `users/{uid}/subscription/status`   premium flag mirrored from RevenueCat
/// `users/{uid}`                       (the parent doc, if it was ever written)
///
/// Add a new per-user collection here or account deletion will leave it behind.
class UserCloudData {
  UserCloudData(this._firestore);

  static const subcollections = ['usage', 'subscription'];

  final FirebaseFirestore _firestore;

  /// Deletes every doc above. Idempotent (nothing there is not an error).
  Future<void> deleteAll(String uid) async {
    final userDoc = _firestore.collection('users').doc(uid);
    for (final name in subcollections) {
      while (true) {
        final page = await userDoc.collection(name).limit(400).get();
        if (page.docs.isEmpty) break;
        final batch = _firestore.batch();
        for (final doc in page.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }
    await userDoc.delete();
  }
}
