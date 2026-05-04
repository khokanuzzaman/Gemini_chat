import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  const AppPreferences._();

  static const onboardingCompleteKey = 'onboarding_complete';
  static const ragEnabledKey = 'rag_enabled';
  static const themeModeKey = 'theme_mode';
  static const defaultCategoryKey = 'default_category';
  static const currencySymbolKey = 'currency_symbol';
  static const dateFormatKey = 'date_format';
  static const aiGuidePromptSeenKey = 'ai_guide_prompt_seen';
  static const handledChatCardKeysKey = 'handled_chat_card_keys';
  static const firstWalletPromptSeenKey = 'first_wallet_prompt_seen';
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
    return (await _prefs).getBool(ragEnabledKey) ?? false;
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

  static Future<bool> isAiGuidePromptSeen() async {
    return (await _prefs).getBool(aiGuidePromptSeenKey) ?? false;
  }

  static Future<void> setAiGuidePromptSeen(bool value) async {
    await (await _prefs).setBool(aiGuidePromptSeenKey, value);
  }

  static Future<bool> isFirstWalletPromptSeen() async {
    return (await _prefs).getBool(firstWalletPromptSeenKey) ?? false;
  }

  static Future<void> setFirstWalletPromptSeen(bool value) async {
    await (await _prefs).setBool(firstWalletPromptSeenKey, value);
  }

  static Future<Set<String>> handledChatCardKeys() async {
    final values = (await _prefs).getStringList(handledChatCardKeysKey);
    return values == null ? <String>{} : values.toSet();
  }

  static Future<void> addHandledChatCardKey(String key) async {
    final prefs = await _prefs;
    final keys =
        prefs.getStringList(handledChatCardKeysKey)?.toSet() ?? <String>{};
    keys.add(key);
    await prefs.setStringList(
      handledChatCardKeysKey,
      keys.toList(growable: false),
    );
  }

  static Future<void> clearHandledChatCardKeys() async {
    await (await _prefs).remove(handledChatCardKeysKey);
  }

  static Future<int?> activeWalletId() async {
    final value = (await _prefs).getInt(_activeWalletIdKey);
    return value == 0 ? null : value;
  }

  static Future<void> setActiveWalletId(int walletId) async {
    await (await _prefs).setInt(_activeWalletIdKey, walletId);
  }
}
