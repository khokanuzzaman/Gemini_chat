import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preferences/app_preferences.dart';

final themeBootstrapProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ref.watch(themeBootstrapProvider);
  }

  bool get isDark {
    if (state == ThemeMode.system) {
      return SchedulerBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return state == ThemeMode.dark;
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await AppPreferences.setThemeMode(mode.name);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);
