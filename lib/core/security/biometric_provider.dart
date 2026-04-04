import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/shared_preferences_provider.dart';
import 'biometric_service.dart';

const _biometricEnabledKey = 'biometric_enabled';
const _biometricLockTimeoutKey = 'biometric_lock_timeout';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

final biometricProvider = NotifierProvider<BiometricNotifier, BiometricState>(
  BiometricNotifier.new,
);

class BiometricState {
  const BiometricState({
    required this.isEnabled,
    required this.isUnlocked,
    required this.lockTimeoutSeconds,
  });

  final bool isEnabled;
  final bool isUnlocked;
  final int lockTimeoutSeconds;

  bool get needsUnlock => isEnabled && !isUnlocked;

  BiometricState copyWith({
    bool? isEnabled,
    bool? isUnlocked,
    int? lockTimeoutSeconds,
  }) {
    return BiometricState(
      isEnabled: isEnabled ?? this.isEnabled,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      lockTimeoutSeconds: lockTimeoutSeconds ?? this.lockTimeoutSeconds,
    );
  }
}

class BiometricNotifier extends Notifier<BiometricState> {
  @override
  BiometricState build() {
    final prefs = _prefsOrNull();
    final isEnabled = prefs?.getBool(_biometricEnabledKey) ?? false;
    final lockTimeoutSeconds = prefs?.getInt(_biometricLockTimeoutKey) ?? 30;

    unawaited(ref.read(biometricServiceProvider).setSecureEnabled(isEnabled));

    return BiometricState(
      isEnabled: isEnabled,
      isUnlocked: false,
      lockTimeoutSeconds: lockTimeoutSeconds,
    );
  }

  Future<BiometricAuthResult> enable() async {
    final result = await ref.read(biometricServiceProvider).authenticate();
    if (result != BiometricAuthResult.success) {
      return result;
    }

    final prefs = _prefsOrNull();
    await prefs?.setBool(_biometricEnabledKey, true);
    state = state.copyWith(isEnabled: true, isUnlocked: true);
    await ref.read(biometricServiceProvider).setSecureEnabled(true);
    return result;
  }

  Future<BiometricAuthResult> disable() async {
    final result = await ref.read(biometricServiceProvider).authenticate();
    if (result != BiometricAuthResult.success) {
      return result;
    }

    final prefs = _prefsOrNull();
    await prefs?.setBool(_biometricEnabledKey, false);
    state = state.copyWith(isEnabled: false, isUnlocked: true);
    await ref.read(biometricServiceProvider).setSecureEnabled(false);
    return result;
  }

  Future<BiometricAuthResult> unlock() async {
    final result = await ref.read(biometricServiceProvider).authenticate();
    if (result == BiometricAuthResult.success) {
      state = state.copyWith(isUnlocked: true);
    }
    return result;
  }

  Future<void> setLockTimeout(int seconds) async {
    final prefs = _prefsOrNull();
    await prefs?.setInt(_biometricLockTimeoutKey, seconds);
    state = state.copyWith(lockTimeoutSeconds: seconds);
  }

  void lock() {
    if (state.isEnabled) {
      state = state.copyWith(isUnlocked: false);
    }
  }

  SharedPreferences? _prefsOrNull() {
    try {
      return ref.read(sharedPreferencesProvider);
    } on UnimplementedError {
      return null;
    }
  }
}
