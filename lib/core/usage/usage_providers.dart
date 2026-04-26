import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/shared_preferences_provider.dart';
import 'usage_status.dart';
import 'usage_tracker_service.dart';

final usageRefreshTokenProvider = StateProvider<int>((ref) => 0);

final usageTrackerServiceProvider = Provider<UsageTrackerService>((ref) {
  return UsageTrackerService(
    firebaseAuth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    prefs: ref.read(sharedPreferencesProvider),
  );
});

final usageStatusProvider = FutureProvider.family<UsageStatus, String>((
  ref,
  feature,
) async {
  ref.watch(usageRefreshTokenProvider);
  return ref.read(usageTrackerServiceProvider).getStatus(feature);
});

final allUsageStatusProvider = FutureProvider<Map<String, UsageStatus>>((
  ref,
) async {
  ref.watch(usageRefreshTokenProvider);
  return ref.read(usageTrackerServiceProvider).getAllStatuses();
});
