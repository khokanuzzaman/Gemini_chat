import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_strings.dart';
import '../../core/backup/backup_providers.dart';
import '../../core/database/expense_seed_data.dart';
import '../../core/database/models/budget_plan_model.dart';
import '../../core/database/models/expense_record_model.dart';
import '../../core/database/models/goal_model.dart';
import '../../core/database/models/goal_saving_model.dart';
import '../../core/database/models/imported_sms_model.dart';
import '../../core/database/models/income_record_model.dart';
import '../../core/database/models/recurring_expense_model.dart';
import '../../core/database/models/sms_ledger_entry_model.dart';
import '../../core/database/models/sms_ledger_sync_state_model.dart';
import '../../core/database/models/split_bill_model.dart';
import '../../core/database/models/wallet_model.dart';
import '../../core/navigation/app_page_route.dart';
import '../../core/navigation/app_shell_navigation.dart';
import '../../core/notifications/budget_settings.dart';
import '../../core/notifications/notification_provider.dart';
import '../../core/notifications/notification_settings.dart';
import '../../core/premium/premium_providers.dart';
import '../../core/premium/premium_service.dart';
import '../../core/preferences/app_preferences.dart';
import '../../core/providers/database_providers.dart';
import '../../core/security/biometric_provider.dart';
import '../../core/security/biometric_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/bangla_formatters.dart';
import '../../core/usage/usage_limits.dart';
import '../../core/widgets/widgets.dart';
import '../ai_guide/presentation/screens/ai_guide_screen.dart';
import '../anomaly/presentation/providers/anomaly_provider.dart';
import '../budget/presentation/providers/budget_provider.dart';
import '../budget/presentation/screens/budget_planner_screen.dart';
import '../category/presentation/providers/category_provider.dart';
import '../category/presentation/screens/category_management_screen.dart';
import '../chat/data/models/message_model.dart';
import '../chat/presentation/providers/chat_provider.dart';
import '../debt/data/models/debt_model.dart';
import '../debt/data/models/debt_payment_model.dart';
import '../debt/presentation/providers/debt_providers.dart';
import '../expense/presentation/providers/expense_providers.dart';
import '../export/presentation/screens/export_screen.dart';
import '../goals/presentation/providers/goal_provider.dart';
import '../goals/presentation/screens/goals_screen.dart';
import '../income/presentation/providers/income_providers.dart';
import '../income/presentation/screens/income_list_screen.dart';
import '../recurring/presentation/screens/recurring_screen.dart';
import '../sms_import/presentation/providers/sms_import_provider.dart';
import '../sms_import/presentation/widgets/sms_import_entry_widgets.dart';
import '../wallet/presentation/providers/wallet_provider.dart';
import '../wallet/presentation/screens/wallet_management_screen.dart';
import 'backup_screen.dart';
import 'budget_settings_screen.dart';
import 'premium_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _currencyOptions = ['৳', 'Tk', 'BDT'];
  static const _dateFormatOptions = ['d MMM yyyy', 'dd/MM/yyyy', 'yyyy-MM-dd'];
  static const _lockTimeoutOptions = [0, 30, 60, 300];

  bool _loading = true;
  bool _ragEnabled = true;
  String _defaultCategory = 'Other';
  String _currencySymbol = '৳';
  String _dateFormat = 'd MMM yyyy';
  String _version = '...';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final packageInfo = await PackageInfo.fromPlatform();
    _ragEnabled = await AppPreferences.isRagEnabled();
    _defaultCategory = await AppPreferences.defaultCategory();
    _currencySymbol = await AppPreferences.currencySymbol();
    _dateFormat = await AppPreferences.dateFormat();

    if (!mounted) {
      return;
    }

    setState(() {
      _version = '${packageInfo.version}+${packageInfo.buildNumber}';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppPageScaffold(
        title: 'সেটিংস',
        body: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.screenPadding),
          child: AppLoadingState.list(),
        ),
      );
    }

    final biometricState = ref.watch(biometricProvider);
    final biometricService = ref.watch(biometricServiceProvider);
    final notificationSettings = ref.watch(notificationProvider);
    final anomalyState = ref.watch(anomalyProvider);
    final goalState = ref.watch(goalProvider);
    final activeBudget = ref.watch(budgetProvider).activeBudget;
    final backupStateAsync = ref.watch(backupStateProvider);
    final backupState = backupStateAsync.valueOrNull;
    final backupSignedIn = backupState?.isSignedIn ?? false;
    final premiumStatusAsync = ref.watch(premiumStatusProvider);
    final premiumStatus = premiumStatusAsync.valueOrNull;
    final premiumOfferingsAsync = ref.watch(premiumOfferingsProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final premiumTeaserTitle = _premiumTeaserTitle(premiumOfferingsAsync);
    final backupSubtitle = isPremium
        ? 'স্বয়ংক্রিয় ব্যাকআপ চালু'
        : 'দৈনিক ${BanglaFormatters.count(UsageLimits.cloudBackupPerDay)}টি ম্যানুয়াল ব্যাকআপ';
    final activeAnomalyCount = anomalyState.activeAlerts.length;
    final activeGoalCount = goalState.activeGoals.length;
    final categories = ref.watch(categoryProvider);
    final categoryNames = categories
        .map((category) => category.name)
        .toList(growable: false);
    final defaultCategory = categoryNames.contains(_defaultCategory)
        ? _defaultCategory
        : 'Other';
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    final sections = <Widget>[
      _SettingsGroup(
        title: 'অ্যাকাউন্ট',
        child: _tileCard(context, [
          AppListTile(
            leadingIcon: Icons.account_balance_wallet_outlined,
            leadingColor: context.appColors.primary,
            title: 'ওয়ালেট ম্যানেজমেন্ট',
            subtitle: 'ক্যাশ, বিকাশ, নগদ ও ব্যাংক ওয়ালেট পরিচালনা করুন',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).push(
                AppSlideRoute(builder: (_) => const WalletManagementScreen()),
              );
            },
          ),
          AppListTile(
            leadingIcon: Icons.category_outlined,
            leadingColor: context.appColors.primary,
            title: 'ক্যাটাগরি ম্যানেজমেন্ট',
            subtitle: 'ডিফল্ট ও কাস্টম ক্যাটাগরি গুছিয়ে রাখুন',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).push(
                AppSlideRoute(builder: (_) => const CategoryManagementScreen()),
              );
            },
          ),
          AppListTile(
            leadingIcon: Icons.trending_up_rounded,
            leadingColor: AppColors.success,
            title: 'আয় ব্যবস্থাপনা',
            subtitle: 'আয়ের উৎস, তালিকা ও সংযোজন দেখুন',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(
                context,
              ).push(AppSlideRoute(builder: (_) => const IncomeListScreen()));
            },
          ),
        ]),
      ),
      _SettingsGroup(
        title: 'বাজেট ও লক্ষ্য',
        child: _tileCard(context, [
          AppListTile(
            leadingIcon: Icons.savings_outlined,
            leadingColor: context.appColors.primary,
            title: 'বাজেট সেটিংস',
            subtitle: 'ক্যাটাগরি অনুযায়ী সীমা সেট করুন',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).push(
                AppSlideRoute(builder: (_) => const BudgetSettingsScreen()),
              );
            },
          ),
          AppListTile(
            leadingIcon: Icons.auto_awesome_rounded,
            leadingColor: context.appColors.primary,
            title: 'বাজেট প্ল্যানার',
            subtitle: activeBudget != null
                ? '${AppStrings.appName} AI আপনার মাসিক বাজেট সাজিয়ে দেবে'
                : 'AI দিয়ে নতুন বাজেট পরিকল্পনা বানান',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).push(
                AppSlideRoute(builder: (_) => const BudgetPlannerScreen()),
              );
            },
          ),
          AppListTile(
            leadingIcon: Icons.flag_rounded,
            leadingColor: context.appColors.primary,
            title: 'লক্ষ্য',
            subtitle: activeGoalCount == 0
                ? 'এখনো কোনো সঞ্চয় লক্ষ্য নেই'
                : '${BanglaFormatters.count(activeGoalCount)}টি চলমান লক্ষ্য আছে',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(
                context,
              ).push(AppSlideRoute(builder: (_) => const GoalsScreen()));
            },
          ),
          AppListTile(
            leadingIcon: Icons.repeat_rounded,
            leadingColor: context.appColors.primary,
            title: 'নিয়মিত খরচ',
            subtitle: 'স্বয়ংক্রিয়ভাবে সনাক্ত হওয়া recurring খরচ দেখুন',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(
                context,
              ).push(AppSlideRoute(builder: (_) => const RecurringScreen()));
            },
          ),
          AppListTile(
            leadingIcon: Icons.call_split_rounded,
            leadingColor: AppColors.warning,
            title: 'স্প্লিট বিল',
            subtitle: 'বন্ধুদের সাথে বিল ভাগ করুন',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).pop();
              AppShellNavigation.openSplit();
            },
          ),
          AppListTile(
            leadingIcon: Icons.handshake_outlined,
            leadingColor: context.appColors.primary,
            title: 'ধার-দেনা',
            subtitle: 'পাওনা, দেনা ও কিস্তি ম্যানেজ করুন',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: AppShellNavigation.openDebts,
          ),
          AppListTile(
            leadingIcon: Icons.warning_amber_rounded,
            leadingColor: activeAnomalyCount > 0
                ? AppColors.warning
                : context.appColors.primary,
            title: 'স্পেন্ডিং অ্যালার্ট',
            subtitle: activeAnomalyCount > 0
                ? '${activeAnomalyCount.toString()}টি সতর্কতা সক্রিয় আছে'
                : 'অস্বাভাবিক খরচ ধরা পড়লে এখানে দেখবেন',
            trailing: activeAnomalyCount > 0
                ? _CountBadge(count: activeAnomalyCount)
                : const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).pop();
              AppShellNavigation.openAnalytics(tabIndex: 1);
            },
          ),
        ]),
      ),
      _SettingsGroup(
        title: 'ক্লাউড ব্যাকআপ',
        child: _tileCard(context, [
          AppListTile(
            leadingIcon: backupSignedIn
                ? Icons.cloud_done_rounded
                : Icons.backup_outlined,
            leadingColor: backupSignedIn
                ? AppColors.success
                : context.appColors.primary,
            title: 'Google Drive ব্যাকআপ',
            subtitle: backupSubtitle,
            trailing: backupSignedIn
                ? const Icon(Icons.chevron_right_rounded)
                : const AppChip(label: 'সেটআপ করুন', selected: false),
            onTap: () {
              Navigator.of(
                context,
              ).push(AppSlideRoute(builder: (_) => const BackupScreen()));
            },
          ),
        ]),
      ),
      _SettingsGroup(
        title: 'Premium',
        child: premiumStatusAsync.when(
          loading: () => const AppLoadingState.card(height: 96),
          error: (error, stackTrace) => _buildPremiumBanner(
            context,
            premiumStatus,
            isPremium,
            teaserTitle: premiumTeaserTitle,
          ),
          data: (status) => _buildPremiumBanner(
            context,
            status,
            status.isPremium,
            teaserTitle: premiumTeaserTitle,
          ),
        ),
      ),
      _SettingsGroup(
        title: 'স্মার্ট ফিচার',
        child: const SmsAutoImportSettingsCard(),
      ),
      _SettingsGroup(
        title: 'ডেটা',
        child: _tileCard(context, [
          const SmsImportSettingsTile(),
          AppListTile(
            leadingIcon: Icons.table_chart_rounded,
            leadingColor: context.appColors.primary,
            title: 'ডেটা এক্সপোর্ট',
            subtitle: 'CSV ফাইলে খরচের হিসাব বের করুন',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(
                context,
              ).push(AppSlideRoute(builder: (_) => const ExportScreen()));
            },
          ),
          AppListTile(
            leadingIcon: Icons.auto_awesome_outlined,
            leadingColor: AppColors.success,
            title: 'ডেমো ডেটা যোগ করুন',
            subtitle: 'ডেমো খরচ যোগ করে ফিচারগুলো দ্রুত দেখে নিন',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _seedDemoData,
          ),
          AppListTile(
            leadingIcon: Icons.delete_outline_rounded,
            leadingColor: AppColors.error,
            title: 'সব ডেটা মুছুন',
            subtitle: 'খরচ, আয়, চ্যাট ও অন্যান্য হিসাব স্থায়ীভাবে মুছে যাবে',
            trailing: Icon(Icons.chevron_right_rounded, color: AppColors.error),
            onTap: _clearAllData,
          ),
        ]),
      ),
      _SettingsGroup(
        title: 'অ্যাপ',
        child: Column(
          children: [
            _tileCard(context, [
              AppListTile(
                leadingIcon: Icons.school_outlined,
                leadingColor: context.appColors.primary,
                title: 'AI Guide',
                subtitle: 'চ্যাট, ভয়েস, রিসিট ও Smart Mode শেখুন',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(AppSlideRoute(builder: (_) => const AiGuideScreen()));
                },
              ),
              AppListTile(
                leadingIcon: Icons.psychology_alt_rounded,
                leadingColor: context.appColors.primary,
                title: 'পার্সোনাল ডেটা ব্যবহার',
                subtitle: _ragEnabled
                    ? 'চালু — Smart Mode আপনার খরচের ডেটা ব্যবহার করবে'
                    : 'বন্ধ — Smart Mode সীমিত থাকবে',
                trailing: Switch.adaptive(
                  value: _ragEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _ragEnabled = value;
                    });
                    ref.read(ragEnabledProvider.notifier).state = value;
                    await AppPreferences.setRagEnabled(value);
                  },
                ),
                onTap: () async {
                  final nextValue = !_ragEnabled;
                  setState(() {
                    _ragEnabled = nextValue;
                  });
                  ref.read(ragEnabledProvider.notifier).state = nextValue;
                  await AppPreferences.setRagEnabled(nextValue);
                },
              ),
              AppListTile(
                leadingIcon: Icons.label_important_outline_rounded,
                leadingColor: context.appColors.primary,
                title: 'ডিফল্ট ক্যাটাগরি',
                subtitle: 'দ্রুত fallback হিসেবে যে ক্যাটাগরি থাকবে',
                trailing: _TrailingDropdown<String>(
                  value: defaultCategory,
                  items: categoryNames,
                  onChanged: (value) async {
                    setState(() {
                      _defaultCategory = value;
                    });
                    await AppPreferences.setDefaultCategory(value);
                  },
                ),
              ),
              AppListTile(
                leadingIcon: Icons.dark_mode_rounded,
                leadingColor: context.appColors.primary,
                title: 'ডার্ক মোড',
                subtitle: isDarkMode ? 'চালু' : 'বন্ধ',
                trailing: Switch.adaptive(
                  value: isDarkMode,
                  onChanged: (value) {
                    ref
                        .read(themeProvider.notifier)
                        .setTheme(value ? ThemeMode.dark : ThemeMode.light);
                  },
                ),
                onTap: () {
                  ref
                      .read(themeProvider.notifier)
                      .setTheme(isDarkMode ? ThemeMode.light : ThemeMode.dark);
                },
              ),
              AppListTile(
                leadingIcon: Icons.currency_exchange_rounded,
                leadingColor: context.appColors.primary,
                title: 'মুদ্রার চিহ্ন',
                subtitle: 'টাকা দেখানোর ধরন বেছে নিন',
                trailing: _TrailingDropdown<String>(
                  value: _currencySymbol,
                  items: _currencyOptions,
                  onChanged: (value) async {
                    setState(() {
                      _currencySymbol = value;
                    });
                    await AppPreferences.setCurrencySymbol(value);
                  },
                ),
              ),
              AppListTile(
                leadingIcon: Icons.calendar_month_rounded,
                leadingColor: context.appColors.primary,
                title: 'তারিখের ফরম্যাট',
                subtitle: 'অ্যাপে তারিখ কীভাবে দেখাবে',
                trailing: _TrailingDropdown<String>(
                  value: _dateFormat,
                  items: _dateFormatOptions,
                  onChanged: (value) async {
                    setState(() {
                      _dateFormat = value;
                    });
                    await AppPreferences.setDateFormat(value);
                  },
                ),
              ),
            ]),
            if (!isPremium) ...[
              const SizedBox(height: AppSpacing.sectionGap),
              const UsageDisplayWidget(),
            ],
            const SizedBox(height: AppSpacing.sectionGap),
            _buildNotificationCard(context, notificationSettings),
          ],
        ),
      ),
      _SettingsGroup(
        title: 'নিরাপত্তা',
        child: FutureBuilder<bool>(
          future: biometricService.isAvailable(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _tileCard(context, const [
                Padding(
                  padding: EdgeInsets.all(AppSpacing.cardPadding),
                  child: AppLoadingState.list(height: 64),
                ),
              ]);
            }

            final isAvailable = snapshot.data ?? false;
            if (!isAvailable) {
              return _tileCard(context, [
                AppListTile(
                  leadingIcon: Icons.fingerprint_rounded,
                  leadingColor: context.secondaryTextColor,
                  title: 'বায়োমেট্রিক লক',
                  subtitle: 'এই ডিভাইসে বায়োমেট্রিক সুবিধা নেই',
                  trailing: const SizedBox.shrink(),
                ),
              ]);
            }

            return _tileCard(context, [
              AppListTile(
                leadingIcon: Icons.fingerprint_rounded,
                leadingColor: biometricState.isEnabled
                    ? context.appColors.primary
                    : context.secondaryTextColor,
                title: 'বায়োমেট্রিক লক',
                subtitle: biometricState.isEnabled
                    ? 'চালু — অ্যাপ খুলতে ভেরিফাই লাগবে'
                    : 'বন্ধ — অ্যাপ সরাসরি খুলবে',
                trailing: Switch.adaptive(
                  value: biometricState.isEnabled,
                  onChanged: _handleBiometricToggle,
                ),
                onTap: () => _handleBiometricToggle(!biometricState.isEnabled),
              ),
              if (biometricState.isEnabled)
                AppListTile(
                  leadingIcon: Icons.timer_outlined,
                  leadingColor: context.appColors.primary,
                  title: 'লক টাইমআউট',
                  subtitle: 'ব্যাকগ্রাউন্ডে গেলে কতক্ষণ পরে আবার লক হবে',
                  trailing: _TrailingDropdown<int>(
                    value: biometricState.lockTimeoutSeconds,
                    items: _lockTimeoutOptions,
                    itemLabelBuilder: _lockTimeoutLabel,
                    onChanged: (value) {
                      ref
                          .read(biometricProvider.notifier)
                          .setLockTimeout(value);
                    },
                  ),
                ),
            ]);
          },
        ),
      ),
      _SettingsGroup(
        title: 'সম্পর্কে',
        child: _tileCard(context, [
          AppListTile(
            leadingIcon: Icons.info_outline_rounded,
            leadingColor: context.appColors.primary,
            title: 'অ্যাপ ভার্সন',
            subtitle: _version,
            trailing: const SizedBox.shrink(),
          ),
          AppListTile(
            leadingIcon: Icons.memory_rounded,
            leadingColor: context.appColors.primary,
            title: AppStrings.poweredBy,
            subtitle: 'GPT-4o mini · Whisper · ML Kit OCR',
            trailing: const SizedBox.shrink(),
          ),
          AppListTile(
            leadingIcon: Icons.link_rounded,
            leadingColor: context.appColors.primary,
            title: 'GitHub লিংক কপি করুন',
            subtitle: 'প্রজেক্ট রিপোজিটরির লিংক ক্লিপবোর্ডে রাখুন',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              const link = 'https://github.com/khokanuzzaman/Gemini_chat';
              await Clipboard.setData(const ClipboardData(text: link));
              if (!mounted) {
                return;
              }
              messenger.showSnackBar(
                const SnackBar(content: Text(AppStrings.githubCopied)),
              );
            },
          ),
        ]),
      ),
    ];

    return AppPageScaffold(
      title: 'সেটিংস',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: AppStaggeredList(children: sections),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationSettings settings,
  ) {
    return _tileCard(context, [
      AppListTile(
        leadingIcon: Icons.notifications_active_outlined,
        leadingColor: context.appColors.primary,
        title: 'দৈনিক রিমাইন্ডার',
        subtitle: settings.dailyReminderEnabled
            ? 'প্রতিদিন ${_formatTimeOfDay(context, settings.dailyReminderTime)}-এ খরচ যোগ করার মনে করিয়ে দেবে'
            : 'খরচ লিখে রাখার জন্য দৈনিক রিমাইন্ডার বন্ধ আছে',
        trailing: Switch.adaptive(
          value: settings.dailyReminderEnabled,
          onChanged: (value) async {
            if (!value) {
              await _updateNotificationSettings(
                settings.copyWith(dailyReminderEnabled: false),
              );
              return;
            }

            final pickedTime = await _pickReminderTime(
              settings.dailyReminderTime,
            );
            await _updateNotificationSettings(
              settings.copyWith(
                dailyReminderEnabled: true,
                dailyReminderTime: pickedTime ?? settings.dailyReminderTime,
              ),
            );
          },
        ),
        onTap: settings.dailyReminderEnabled
            ? () => _changeReminderTime(settings)
            : null,
      ),
      AppListTile(
        leadingIcon: Icons.savings_outlined,
        leadingColor: AppColors.warning,
        title: 'বাজেট সতর্কতা',
        subtitle: settings.budgetAlertEnabled
            ? 'বাজেটের ${settings.budgetAlertThreshold.toStringAsFixed(0)}% হলে সতর্ক করবে'
            : 'বাজেট অ্যালার্ট বন্ধ আছে',
        trailing: Switch.adaptive(
          value: settings.budgetAlertEnabled,
          onChanged: (value) async {
            await _updateNotificationSettings(
              settings.copyWith(budgetAlertEnabled: value),
            );
          },
        ),
      ),
      if (settings.budgetAlertEnabled)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.cardPadding,
            0,
            AppSpacing.cardPadding,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Slider(
                value: settings.budgetAlertThreshold,
                min: 50,
                max: 100,
                divisions: 10,
                label: '${settings.budgetAlertThreshold.toStringAsFixed(0)}%',
                onChanged: (value) async {
                  await _updateNotificationSettings(
                    settings.copyWith(budgetAlertThreshold: value),
                  );
                },
              ),
              Text(
                'বর্তমান থ্রেশহোল্ড: ${settings.budgetAlertThreshold.toStringAsFixed(0)}%',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      AppListTile(
        leadingIcon: Icons.bar_chart_rounded,
        leadingColor: context.appColors.primary,
        title: 'সাপ্তাহিক রিপোর্ট',
        subtitle: 'প্রতি রোববার সকাল ৯টায় সারাংশ পেতে চাই',
        trailing: Switch.adaptive(
          value: settings.weeklyReportEnabled,
          onChanged: (value) async {
            await _updateNotificationSettings(
              settings.copyWith(weeklyReportEnabled: value),
            );
          },
        ),
      ),
    ]);
  }

  Widget _tileCard(BuildContext context, List<Widget> children) {
    return AppCard(
      elevation: 1,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              Divider(
                height: 1,
                color: context.borderColor.withValues(alpha: 0.3),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPremiumBanner(
    BuildContext context,
    PremiumStatus? status,
    bool isPremium, {
    required String teaserTitle,
  }) {
    if (isPremium && status != null) {
      final expiryText = status.expiryDate != null
          ? BanglaFormatters.fullDate(status.expiryDate!)
          : 'Premium সক্রিয়';
      return AppCard(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(
              alpha: context.isDarkMode ? 0.22 : 0.12,
            ),
            context.cardBackgroundColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () {
          Navigator.of(
            context,
          ).push(AppSlideRoute(builder: (_) => const PremiumScreen()));
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Premium সদস্য',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    expiryText,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      );
    }

    return AppCard(
      gradient: LinearGradient(
        colors: [
          context.appColors.primary.withValues(
            alpha: context.isDarkMode ? 0.22 : 0.1,
          ),
          context.cardBackgroundColor,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onTap: () {
        Navigator.of(
          context,
        ).push(AppSlideRoute(builder: (_) => const PremiumScreen()));
      },
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: context.isDarkMode ? 0.1 : 0.55,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star_rounded, color: AppColors.warning),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teaserTitle,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.primaryTextColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'সীমা ছাড়া AI, স্ক্যান আর স্মার্ট ব্যাকআপ পান',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.secondaryTextColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }

  String _premiumTeaserTitle(AsyncValue<List<PremiumPackage>> offeringsAsync) {
    final packages = offeringsAsync.valueOrNull;
    if (packages == null || packages.isEmpty) {
      return 'Premium-এ আপগ্রেড করুন';
    }

    PremiumPackage? monthly;
    for (final package in packages) {
      if (!package.isYearly) {
        monthly = package;
        break;
      }
    }
    final selected = monthly ?? packages.first;
    // TODO: append yearly savings hint when both monthly and yearly packages
    // exist. Skipped because PremiumPackage exposes only priceString (formatted
    // Bangla/USD) without a numeric priceAmount. Adding numeric pricing would
    // require changing PremiumPackage to surface rcPackage.storeProduct.price,
    // which is out of scope for this dashboard polish pass.
    return 'Premium-এ আপগ্রেড করুন · ${selected.priceString}';
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'সব ডেটা মুছে ফেলবেন?',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: context.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'চ্যাট, খরচ, আয়, ধার-দেনা, ওয়ালেট, লক্ষ্য এবং বাজেটসহ সব ডেটা স্থায়ীভাবে মুছে যাবে।',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.secondaryTextColor,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppActionButton(
                    label: 'বাদ দিন',
                    variant: AppActionButtonVariant.ghost,
                    fullWidth: true,
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppActionButton(
                    label: 'মুছুন',
                    variant: AppActionButtonVariant.danger,
                    fullWidth: true,
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(smsAutoImportProvider.notifier).disable();
    await ref.read(backupStateProvider.notifier).signOut();
    await ref.read(backupStateProvider.notifier).resetLocalState();
    await ref.read(isarProvider).writeTxn(() async {
      await ref.read(isarProvider).expenseRecordModels.clear();
      await ref.read(isarProvider).incomeRecordModels.clear();
      await ref.read(isarProvider).messageModels.clear();
      await ref.read(isarProvider).walletModels.clear();
      await ref.read(isarProvider).budgetPlanModels.clear();
      await ref.read(isarProvider).goalModels.clear();
      await ref.read(isarProvider).goalSavingModels.clear();
      await ref.read(isarProvider).recurringExpenseModels.clear();
      await ref.read(isarProvider).splitBillModels.clear();
      await ref.read(isarProvider).debtModels.clear();
      await ref.read(isarProvider).debtPaymentModels.clear();
      await ref.read(isarProvider).importedSmsModels.clear();
      await ref.read(isarProvider).smsLedgerEntryModels.clear();
      await ref.read(isarProvider).smsLedgerSyncStateModels.clear();
    });

    await AppPreferences.setActiveWalletId(0);
    await ref.read(smsSettingsProvider).resetAll();
    await ref.read(budgetSettingsProvider.notifier).clearBudgets();
    await ref.read(anomalyProvider.notifier).clear();
    ref.read(expenseRefreshTokenProvider.notifier).state++;
    ref.read(incomeRefreshTokenProvider.notifier).state++;
    ref.read(debtRefreshTokenProvider.notifier).state++;
    ref.invalidate(budgetProvider);
    ref.invalidate(goalsProvider);
    ref.invalidate(walletProvider);
    ref.invalidate(incomeListControllerProvider);
    ref.invalidate(debtListProvider);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(AppStrings.allDataCleared)));
  }

  Future<void> _seedDemoData() async {
    await ref.read(isarProvider).writeTxn(() async {
      await ref.read(isarProvider).expenseRecordModels.clear();
    });
    await ExpenseSeedData.forceSeed(ref.read(expenseLocalDataSourceProvider));
    ref.read(expenseRefreshTokenProvider.notifier).state++;
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(AppStrings.demoDataSeeded)));
  }

  Future<void> _handleBiometricToggle(bool value) async {
    final notifier = ref.read(biometricProvider.notifier);
    final result = value ? await notifier.enable() : await notifier.disable();

    if (!mounted) {
      return;
    }

    if (result == BiometricAuthResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'বায়োমেট্রিক লক চালু হয়েছে'
                : 'বায়োমেট্রিক লক বন্ধ হয়েছে',
          ),
        ),
      );
      return;
    }

    if (result == BiometricAuthResult.notEnrolled) {
      await _showBiometricEnrollmentDialog();
      return;
    }

    final message = switch (result) {
      BiometricAuthResult.notAvailable => 'বায়োমেট্রিক সুবিধা পাওয়া যায়নি',
      BiometricAuthResult.lockedOut => 'অনেকবার ব্যর্থ হয়েছে, পরে চেষ্টা করুন',
      BiometricAuthResult.failed => 'ভেরিফাই করা যায়নি',
      BiometricAuthResult.success => null,
      BiometricAuthResult.notEnrolled => null,
    };

    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _showBiometricEnrollmentDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('বায়োমেট্রিক সেট করা নেই'),
          content: const Text(
            'এই ডিভাইসে এখনো fingerprint বা face ID সেট করা নেই। সেটিংস থেকে সেট করে আবার চেষ্টা করুন।',
          ),
          actions: [
            AppActionButton(
              label: 'বাদ দিন',
              variant: AppActionButtonVariant.ghost,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            AppActionButton(
              label: 'সেটিংসে যান',
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeReminderTime(NotificationSettings settings) async {
    final pickedTime = await _pickReminderTime(settings.dailyReminderTime);
    if (pickedTime == null) {
      return;
    }

    await _updateNotificationSettings(
      settings.copyWith(dailyReminderTime: pickedTime),
    );
  }

  Future<TimeOfDay?> _pickReminderTime(TimeOfDay initialTime) {
    return showTimePicker(context: context, initialTime: initialTime);
  }

  Future<void> _updateNotificationSettings(
    NotificationSettings settings,
  ) async {
    await ref.read(notificationProvider.notifier).updateSettings(settings);
  }

  String _formatTimeOfDay(BuildContext context, TimeOfDay time) {
    return MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(time, alwaysUse24HourFormat: false);
  }

  String _lockTimeoutLabel(int seconds) {
    return switch (seconds) {
      0 => 'সাথে সাথে',
      30 => '৩০ সেকেন্ড',
      60 => '১ মিনিট',
      300 => '৫ মিনিট',
      _ => '$seconds সেকেন্ড',
    };
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: title),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return AppChip(
      label: count > 9 ? '9+' : '$count',
      color: AppColors.error,
      compact: true,
    );
  }
}

class _TrailingDropdown<T> extends StatelessWidget {
  const _TrailingDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabelBuilder,
  });

  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;
  final String Function(T value)? itemLabelBuilder;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        style: AppTextStyles.bodySmall.copyWith(
          color: context.primaryTextColor,
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabelBuilder?.call(item) ?? '$item'),
              ),
            )
            .toList(growable: false),
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
    );
  }
}
