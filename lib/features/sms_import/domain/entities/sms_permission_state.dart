enum SmsPermissionState { unsupported, granted, denied, permanentlyDenied }

extension SmsPermissionStateX on SmsPermissionState {
  bool get isGranted => this == SmsPermissionState.granted;

  bool get isSupported => this != SmsPermissionState.unsupported;
}
