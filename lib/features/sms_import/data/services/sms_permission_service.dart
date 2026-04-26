import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/sms_permission_state.dart';

class SmsPermissionService {
  const SmsPermissionService();

  bool get isSupported => Platform.isAndroid;

  Future<SmsPermissionState> getStatus() async {
    if (!isSupported) {
      return SmsPermissionState.unsupported;
    }

    final status = await Permission.sms.status;
    return _mapStatus(status);
  }

  Future<SmsPermissionState> requestPermission() async {
    if (!isSupported) {
      return SmsPermissionState.unsupported;
    }

    final status = await Permission.sms.request();
    return _mapStatus(status);
  }

  Future<void> ensurePermission() async {
    final current = await getStatus();
    if (current == SmsPermissionState.granted) {
      return;
    }

    if (current == SmsPermissionState.unsupported) {
      throw const GeneralException('SMS অটো-ইমপোর্ট শুধু Android-এ কাজ করে।');
    }

    final requested = await requestPermission();
    if (requested == SmsPermissionState.granted) {
      return;
    }

    if (requested == SmsPermissionState.permanentlyDenied) {
      throw const PermissionDeniedException(
        'SMS পড়ার অনুমতি সেটিংস থেকে চালু করুন।',
      );
    }

    throw const PermissionDeniedException('SMS পড়ার অনুমতি দিন।');
  }

  Future<bool> openSettings() => openAppSettings();

  SmsPermissionState _mapStatus(PermissionStatus status) {
    if (status.isGranted) {
      return SmsPermissionState.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return SmsPermissionState.permanentlyDenied;
    }
    return SmsPermissionState.denied;
  }
}
