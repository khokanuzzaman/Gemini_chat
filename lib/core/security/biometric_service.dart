import 'dart:io';

import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

enum BiometricAuthResult {
  success,
  failed,
  notAvailable,
  notEnrolled,
  lockedOut,
}

class BiometricService {
  BiometricService({LocalAuthentication? auth, MethodChannel? securityChannel})
    : _auth = auth ?? LocalAuthentication(),
      _securityChannel =
          securityChannel ?? const MethodChannel('pocketpilot_ai/security');

  final LocalAuthentication _auth;
  final MethodChannel _securityChannel;

  Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  Future<BiometricAuthResult> authenticate() async {
    try {
      final available = await isAvailable();
      if (!available) {
        return BiometricAuthResult.notAvailable;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: 'PocketPilot AI খুলতে verify করুন',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );

      return authenticated
          ? BiometricAuthResult.success
          : BiometricAuthResult.failed;
    } on PlatformException catch (error) {
      if (error.code == auth_error.notAvailable) {
        return BiometricAuthResult.notAvailable;
      }
      if (error.code == auth_error.notEnrolled) {
        return BiometricAuthResult.notEnrolled;
      }
      if (error.code == auth_error.lockedOut ||
          error.code == auth_error.permanentlyLockedOut) {
        return BiometricAuthResult.lockedOut;
      }
      return BiometricAuthResult.failed;
    } catch (_) {
      return BiometricAuthResult.failed;
    }
  }

  Future<void> setSecureEnabled(bool enabled) async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      await _securityChannel.invokeMethod<void>('setSecureEnabled', {
        'enabled': enabled,
      });
    } catch (_) {}
  }
}
