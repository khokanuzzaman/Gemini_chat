import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'biometric_provider.dart';

class AppLifecycleObserver extends WidgetsBindingObserver {
  AppLifecycleObserver({required WidgetRef ref}) : _ref = ref;

  final WidgetRef _ref;
  Timer? _lockTimer;
  DateTime? _backgroundedAt;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final biometric = _ref.read(biometricProvider);
    if (!biometric.isEnabled) {
      _backgroundedAt = null;
      _cancelLockTimer();
      return;
    }

    // `inactive` also fires for transient system overlays such as auth prompts.
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _handleBackgrounding();
    }

    if (state == AppLifecycleState.resumed) {
      _handleResume();
    }
  }

  void dispose() {
    _cancelLockTimer();
  }

  void _startLockTimer() {
    _lockTimer?.cancel();
    final timeout = _ref.read(biometricProvider).lockTimeoutSeconds;
    if (timeout <= 0) {
      _backgroundedAt = null;
      _ref.read(biometricProvider.notifier).lock();
      return;
    }

    _lockTimer = Timer(Duration(seconds: timeout), () {
      _backgroundedAt = null;
      _ref.read(biometricProvider.notifier).lock();
    });
  }

  void _handleBackgrounding() {
    _backgroundedAt ??= DateTime.now();
    _startLockTimer();
  }

  void _handleResume() {
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    _cancelLockTimer();
    if (backgroundedAt == null) {
      return;
    }

    final timeout = _ref.read(biometricProvider).lockTimeoutSeconds;
    if (timeout <= 0 ||
        DateTime.now().difference(backgroundedAt) >=
            Duration(seconds: timeout)) {
      _ref.read(biometricProvider.notifier).lock();
    }
  }

  void _cancelLockTimer() {
    _lockTimer?.cancel();
    _lockTimer = null;
  }
}
