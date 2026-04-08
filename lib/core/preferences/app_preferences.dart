import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  const AppPreferences._();

  static const onboardingCompleteKey = 'onboarding_complete';
  static const ragEnabledKey = 'rag_enabled';
  static const themeModeKey = 'theme_mode';
  static const defaultCategoryKey = 'default_category';
  static const currencySymbolKey = 'currency_symbol';
  static const dateFormatKey = 'date_format';
  static const _activeWalletIdKey = 'active_wallet_id';

  static Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  static Future<bool> isOnboardingComplete() async {
    return (await _prefs).getBool(onboardingCompleteKey) ?? false;
  }

  static Future<void> setOnboardingComplete(bool value) async {
    await (await _prefs).setBool(onboardingCompleteKey, value);
  }

  static Future<bool> isRagEnabled() async {
    return (await _prefs).getBool(ragEnabledKey) ?? true;
  }

  static Future<void> setRagEnabled(bool value) async {
    await (await _prefs).setBool(ragEnabledKey, value);
  }

  static Future<String> themeMode() async {
    return (await _prefs).getString(themeModeKey) ?? 'system';
  }

  static Future<void> setThemeMode(String value) async {
    await (await _prefs).setString(themeModeKey, value);
  }

  static Future<String> defaultCategory() async {
    return (await _prefs).getString(defaultCategoryKey) ?? 'Other';
  }

  static Future<void> setDefaultCategory(String value) async {
    await (await _prefs).setString(defaultCategoryKey, value);
  }

  static Future<String> currencySymbol() async {
    return (await _prefs).getString(currencySymbolKey) ?? '৳';
  }

  static Future<void> setCurrencySymbol(String value) async {
    await (await _prefs).setString(currencySymbolKey, value);
  }

  static Future<String> dateFormat() async {
    return (await _prefs).getString(dateFormatKey) ?? 'd MMM yyyy';
  }

  static Future<void> setDateFormat(String value) async {
    await (await _prefs).setString(dateFormatKey, value);
  }

  static Future<int?> activeWalletId() async {
    final value = (await _prefs).getInt(_activeWalletIdKey);
    return value == 0 ? null : value;
  }

  static Future<void> setActiveWalletId(int walletId) async {
    await (await _prefs).setInt(_activeWalletIdKey, walletId);
  }
}
