import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SmsSettings {
  SmsSettings(this._preferences);

  static const smsAutoImportEnabledKey = 'sms_auto_import_enabled';
  static const smsAutoConfirmKey = 'sms_auto_confirm';
  static const smsImportSourcesKey = 'sms_import_sources';
  static const smsLastScanTimeKey = 'sms_last_scan_time';
  static const smsImportedCountKey = 'sms_imported_count';

  static const List<String> defaultEnabledSources = [
    'bKash',
    'Nagad',
    'Rocket',
    'Bank',
  ];

  final SharedPreferences _preferences;

  bool isAutoImportEnabled() {
    return _preferences.getBool(smsAutoImportEnabledKey) ?? false;
  }

  Future<void> setAutoImportEnabled(bool value) {
    return _preferences.setBool(smsAutoImportEnabledKey, value);
  }

  bool isAutoConfirmEnabled() {
    return _preferences.getBool(smsAutoConfirmKey) ?? false;
  }

  Future<void> setAutoConfirmEnabled(bool value) {
    return _preferences.setBool(smsAutoConfirmKey, value);
  }

  List<String> getEnabledSources() {
    final raw = _preferences.getString(smsImportSourcesKey);
    if (raw == null || raw.trim().isEmpty) {
      return List<String>.from(defaultEnabledSources);
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final values = decoded
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList(growable: false);
        if (values.isNotEmpty) {
          return values;
        }
      }
    } catch (_) {}

    return List<String>.from(defaultEnabledSources);
  }

  Future<void> setEnabledSources(List<String> sources) {
    final normalized = sources
        .map((source) => source.trim())
        .where((source) => source.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return _preferences.setString(
      smsImportSourcesKey,
      jsonEncode(normalized),
    );
  }

  DateTime? getLastScanTime() {
    final millis = _preferences.getInt(smsLastScanTimeKey);
    if (millis == null || millis <= 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setLastScanTime(DateTime? time) async {
    if (time == null) {
      await _preferences.remove(smsLastScanTimeKey);
      return;
    }
    await _preferences.setInt(
      smsLastScanTimeKey,
      time.millisecondsSinceEpoch,
    );
  }

  int getImportedCount() {
    return _preferences.getInt(smsImportedCountKey) ?? 0;
  }

  Future<void> setImportedCount(int count) {
    return _preferences.setInt(smsImportedCountKey, count);
  }

  Future<void> incrementImportedCount([int by = 1]) {
    final current = getImportedCount();
    return setImportedCount(current + by);
  }

  Future<void> resetAll() async {
    await _preferences.remove(smsAutoImportEnabledKey);
    await _preferences.remove(smsAutoConfirmKey);
    await _preferences.remove(smsImportSourcesKey);
    await _preferences.remove(smsLastScanTimeKey);
    await _preferences.remove(smsImportedCountKey);
  }
}
