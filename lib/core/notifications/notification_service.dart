import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../navigation/app_shell_navigation.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int dailyReminderId = 1;
  static const int budgetAlertId = 2;
  static const int weeklyReportId = 3;
  static const int anomalyAlertId = 4;
  static const int goalReminderPreviewId = 5;

  static const AndroidNotificationChannel _dailyReminderChannel =
      AndroidNotificationChannel(
        'daily_reminder',
        'Daily Reminder',
        description: 'Daily expense reminder',
        importance: Importance.defaultImportance,
      );

  static const AndroidNotificationChannel _budgetAlertChannel =
      AndroidNotificationChannel(
        'budget_alert',
        'Budget Alert',
        description: 'Budget threshold alerts',
        importance: Importance.high,
      );

  static const AndroidNotificationChannel _weeklyReportChannel =
      AndroidNotificationChannel(
        'weekly_report',
        'Weekly Report',
        description: 'Weekly spending summary',
        importance: Importance.defaultImportance,
      );

  static const AndroidNotificationChannel _anomalyAlertChannel =
      AndroidNotificationChannel(
        'anomaly_alert',
        'Anomaly Alert',
        description: 'Unusual spending alerts',
        importance: Importance.high,
      );

  static const AndroidNotificationChannel _goalReminderChannel =
      AndroidNotificationChannel(
        'goal_reminder',
        'Goal Reminder',
        description: 'Monthly goal saving reminders',
        importance: Importance.defaultImportance,
      );

  static Future<void> initialize() async {
    await _initTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_dailyReminderChannel);
    await androidPlugin?.createNotificationChannel(_budgetAlertChannel);
    await androidPlugin?.createNotificationChannel(_weeklyReportChannel);
    await androidPlugin?.createNotificationChannel(_anomalyAlertChannel);
    await androidPlugin?.createNotificationChannel(_goalReminderChannel);

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    _handlePayload(launchDetails?.notificationResponse?.payload);
  }

  static Future<void> _initTimezone() async {
    tz_data.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    _handlePayload(response.payload);
  }

  static void _handlePayload(String? payload) {
    AppShellNavigation.handlePayload(payload);
  }

  static Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await androidPlugin?.requestNotificationsPermission();
      try {
        await androidPlugin?.requestExactAlarmsPermission();
      } catch (_) {}
      return granted ?? true;
    }

    if (Platform.isIOS || Platform.isMacOS) {
      final iosPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosPlugin != null) {
        return await iosPlugin.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }

      final macOsPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      return await macOsPlugin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return true;
  }

  static Future<void> scheduleDailyReminder({required TimeOfDay time}) async {
    await _plugin.cancel(dailyReminderId);

    await _plugin.zonedSchedule(
      dailyReminderId,
      '💰 খরচ যোগ করুন',
      'আজকের খরচ এখনো add করেননি',
      _nextInstanceOfTime(time),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminder',
          channelDescription: 'Daily expense reminder',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );
  }

  static Future<void> cancelDailyReminder() async {
    await _plugin.cancel(dailyReminderId);
  }

  static Future<void> showBudgetAlert({
    required String category,
    required double spent,
    required double budget,
    required double percentage,
  }) async {
    final title = percentage >= 100
        ? '🚨 $category budget শেষ!'
        : '⚠️ $category budget সতর্কতা';

    final body = percentage >= 100
        ? '$category এ ৳${spent.toStringAsFixed(0)} খরচ — budget ছাড়িয়ে গেছে'
        : '$category budget এর ${percentage.toStringAsFixed(0)}% শেষ (৳${spent.toStringAsFixed(0)} / ৳${budget.toStringAsFixed(0)})';

    await _plugin.show(
      budgetAlertId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'budget_alert',
          'Budget Alert',
          channelDescription: 'Budget threshold alerts',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFFEA4335),
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      payload: 'budget_alert',
    );
  }

  static Future<void> scheduleWeeklyReport() async {
    await _plugin.cancel(weeklyReportId);

    await _plugin.zonedSchedule(
      weeklyReportId,
      '📊 সাপ্তাহিক রিপোর্ট',
      'এই সপ্তাহে কত খরচ হয়েছে দেখুন',
      _nextSunday9AM(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_report',
          'Weekly Report',
          channelDescription: 'Weekly spending summary',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weekly_report',
    );
  }

  static Future<void> showAnomalyAlert({
    required String category,
    required String message,
    required double percentage,
  }) async {
    await _plugin.show(
      anomalyAlertId,
      '⚠️ অস্বাভাবিক খরচ',
      '$category এ স্বাভাবিকের চেয়ে ${percentage.toStringAsFixed(0)}% বেশি\n$message',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'anomaly_alert',
          'Anomaly Alert',
          channelDescription: 'Unusual spending alerts',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFFEA4335),
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      payload: 'anomaly_alert',
    );
  }

  static Future<void> showGoalReminder({
    required String goalTitle,
    required double monthlyNeeded,
  }) async {
    await _plugin.show(
      goalReminderPreviewId,
      '🎯 Goal reminder',
      '$goalTitle — এই মাসে ৳${monthlyNeeded.toStringAsFixed(0)} save করার কথা',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'goal_reminder',
          'Goal Reminder',
          channelDescription: 'Monthly goal saving reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      payload: 'goal_reminder',
    );
  }

  static Future<void> scheduleGoalReminder({
    required int notificationId,
    required String goalTitle,
    required double monthlyNeeded,
  }) async {
    await _plugin.cancel(notificationId);

    await _plugin.zonedSchedule(
      notificationId,
      '🎯 Goal reminder',
      '$goalTitle — এই মাসে ৳${monthlyNeeded.toStringAsFixed(0)} save করার কথা',
      _nextGoalReminderDate(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'goal_reminder',
          'Goal Reminder',
          channelDescription: 'Monthly goal saving reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      payload: 'goal_reminder',
    );
  }

  static Future<void> cancelGoalReminder(int notificationId) async {
    await _plugin.cancel(notificationId);
  }

  static Future<void> cancelWeeklyReport() async {
    await _plugin.cancel(weeklyReportId);
  }

  static tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  static tz.TZDateTime _nextSunday9AM() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);

    while (scheduled.weekday != DateTime.sunday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  static tz.TZDateTime _nextGoalReminderDate() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, 15, 9);

    if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
      scheduled = tz.TZDateTime(tz.local, now.year, now.month + 1, 15, 9);
    }

    return scheduled;
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
