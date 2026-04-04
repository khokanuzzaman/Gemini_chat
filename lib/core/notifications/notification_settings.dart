import 'dart:convert';

import 'package:flutter/material.dart';

class NotificationSettings {
  const NotificationSettings({
    required this.dailyReminderEnabled,
    required this.dailyReminderTime,
    required this.budgetAlertEnabled,
    required this.budgetAlertThreshold,
    required this.weeklyReportEnabled,
  });

  final bool dailyReminderEnabled;
  final TimeOfDay dailyReminderTime;
  final bool budgetAlertEnabled;
  final double budgetAlertThreshold;
  final bool weeklyReportEnabled;

  factory NotificationSettings.defaults() {
    return const NotificationSettings(
      dailyReminderEnabled: true,
      dailyReminderTime: TimeOfDay(hour: 21, minute: 0),
      budgetAlertEnabled: true,
      budgetAlertThreshold: 80,
      weeklyReportEnabled: true,
    );
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      dailyReminderEnabled: json['dailyReminderEnabled'] as bool? ?? true,
      dailyReminderTime: TimeOfDay(
        hour: json['dailyReminderHour'] as int? ?? 21,
        minute: json['dailyReminderMinute'] as int? ?? 0,
      ),
      budgetAlertEnabled: json['budgetAlertEnabled'] as bool? ?? true,
      budgetAlertThreshold:
          (json['budgetAlertThreshold'] as num?)?.toDouble() ?? 80,
      weeklyReportEnabled: json['weeklyReportEnabled'] as bool? ?? true,
    );
  }

  static NotificationSettings? fromJsonString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return NotificationSettings.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  NotificationSettings copyWith({
    bool? dailyReminderEnabled,
    TimeOfDay? dailyReminderTime,
    bool? budgetAlertEnabled,
    double? budgetAlertThreshold,
    bool? weeklyReportEnabled,
  }) {
    return NotificationSettings(
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
      budgetAlertEnabled: budgetAlertEnabled ?? this.budgetAlertEnabled,
      budgetAlertThreshold: budgetAlertThreshold ?? this.budgetAlertThreshold,
      weeklyReportEnabled: weeklyReportEnabled ?? this.weeklyReportEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyReminderEnabled': dailyReminderEnabled,
      'dailyReminderHour': dailyReminderTime.hour,
      'dailyReminderMinute': dailyReminderTime.minute,
      'budgetAlertEnabled': budgetAlertEnabled,
      'budgetAlertThreshold': budgetAlertThreshold,
      'weeklyReportEnabled': weeklyReportEnabled,
    };
  }

  String toJsonString() => jsonEncode(toJson());
}
