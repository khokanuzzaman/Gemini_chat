import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'usage_gate_result.dart';
import 'usage_limits.dart';
import 'usage_status.dart';

class UsageTrackerService {
  UsageTrackerService({
    required this.firebaseAuth,
    required this.firestore,
    required this.prefs,
  });

  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final SharedPreferences prefs;

  bool get _isSignedIn => firebaseAuth.currentUser != null;

  String get _uid => firebaseAuth.currentUser!.uid;

  String _dailyKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  String _monthlyKey() => DateFormat('yyyy-MM').format(DateTime.now());

  String _periodKey(String feature) {
    return UsageLimits.isMonthly(feature) ? _monthlyKey() : _dailyKey();
  }

  String _localKey(String feature) => 'usage_${feature}_${_periodKey(feature)}';

  String _firestorePath(String feature) =>
      '/users/$_uid/usage/${_periodKey(feature)}';

  DocumentReference<Map<String, dynamic>> _usageDocumentFromPath(String path) {
    return firestore.doc(path.replaceFirst('/', ''));
  }

  int _readCountFromData(Map<String, dynamic>? data, String feature) {
    final rawValue = data?[feature];
    return rawValue is num ? rawValue.toInt() : 0;
  }

  DateTime _resetAtFor(String feature) {
    final now = DateTime.now();
    if (UsageLimits.isMonthly(feature)) {
      return DateTime(now.year, now.month + 1, 1);
    }
    return DateTime(now.year, now.month, now.day + 1);
  }

  UsageStatus _statusFor({
    required String feature,
    required int used,
    DateTime? resetAt,
  }) {
    return UsageStatus(
      feature: feature,
      used: used,
      limit: UsageLimits.limitFor(feature),
      isMonthly: UsageLimits.isMonthly(feature),
      resetAt: resetAt ?? _resetAtFor(feature),
    );
  }

  Future<int> getCount(String feature) async {
    final localCount = prefs.getInt(_localKey(feature)) ?? 0;
    if (!_isSignedIn) {
      return localCount;
    }

    try {
      final snapshot = await _usageDocumentFromPath(
        _firestorePath(feature),
      ).get();
      final remoteCount = _readCountFromData(snapshot.data(), feature);
      final resolvedCount = max(localCount, remoteCount);
      if (resolvedCount != localCount) {
        await prefs.setInt(_localKey(feature), resolvedCount);
      }
      return resolvedCount;
    } catch (_) {
      return localCount;
    }
  }

  Future<void> increment(String feature) async {
    final localKey = _localKey(feature);
    final nextCount = (prefs.getInt(localKey) ?? 0) + 1;
    await prefs.setInt(localKey, nextCount);

    if (!_isSignedIn) {
      return;
    }

    try {
      await _usageDocumentFromPath(
        _firestorePath(feature),
      ).set({feature: FieldValue.increment(1)}, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<bool> hasReachedLimit(String feature) async {
    final count = await getCount(feature);
    return count >= UsageLimits.limitFor(feature);
  }

  Future<UsageStatus> getStatus(String feature) async {
    final count = await getCount(feature);
    return _statusFor(feature: feature, used: count);
  }

  Future<UsageGateResult> checkAndConsume(String feature) async {
    final status = await getStatus(feature);
    if (status.hasReachedLimit) {
      return UsageGateResult.blocked(status);
    }

    await increment(feature);
    return UsageGateResult.allowed(
      _statusFor(
        feature: feature,
        used: status.used + 1,
        resetAt: status.resetAt,
      ),
    );
  }

  Future<Map<String, UsageStatus>> getAllStatuses() async {
    final entries = await Future.wait(
      UsageLimits.allFeatures.map((feature) async {
        return MapEntry(feature, await getStatus(feature));
      }),
    );
    return Map<String, UsageStatus>.fromEntries(entries);
  }

  Future<void> syncFromFirestore() async {
    if (!_isSignedIn) {
      return;
    }

    try {
      final documentCache = <String, Map<String, dynamic>?>{};
      for (final feature in UsageLimits.allFeatures) {
        final path = _firestorePath(feature);
        final localKey = _localKey(feature);
        final localCount = prefs.getInt(localKey) ?? 0;
        if (!documentCache.containsKey(path)) {
          final snapshot = await _usageDocumentFromPath(path).get();
          documentCache[path] = snapshot.data();
        }
        final remoteCount = _readCountFromData(documentCache[path], feature);
        await prefs.setInt(localKey, max(localCount, remoteCount));
      }
    } catch (_) {}
  }
}
