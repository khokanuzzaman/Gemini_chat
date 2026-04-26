import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class SmsPermissionHandler {
  const SmsPermissionHandler();

  Future<bool> isAvailable() async {
    return Platform.isAndroid;
  }

  Future<bool> hasPermission() async {
    if (!Platform.isAndroid) {
      return false;
    }
    return (await Permission.sms.status).isGranted;
  }

  Future<PermissionStatus> checkStatus() async {
    if (!Platform.isAndroid) {
      return PermissionStatus.restricted;
    }
    return Permission.sms.status;
  }

  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) {
      return false;
    }

    final currentStatus = await Permission.sms.status;
    if (currentStatus.isGranted) {
      return true;
    }

    if (_shouldOpenSettings(currentStatus)) {
      await openAppSettings();
      return false;
    }

    final requestedStatus = await Permission.sms.request();
    if (requestedStatus.isGranted) {
      return true;
    }

    if (_shouldOpenSettings(requestedStatus)) {
      await openAppSettings();
    }

    return false;
  }

  bool _shouldOpenSettings(PermissionStatus status) {
    return status.isPermanentlyDenied || status.isRestricted;
  }
}
