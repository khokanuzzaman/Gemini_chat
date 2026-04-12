import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_strings.dart';
import '../../core/database/expense_seed_data.dart';
import '../../core/database/models/budget_plan_model.dart';
import '../../core/database/models/expense_record_model.dart';
import '../../core/database/models/goal_model.dart';
import '../../core/database/models/goal_saving_model.dart';
import '../../core/database/models/income_record_model.dart';
import '../../core/database/models/recurring_expense_model.dart';
import '../../core/database/models/split_bill_model.dart';
import '../../core/database/models/wallet_model.dart';
import '../../core/navigation/app_page_route.dart';
import '../../core/navigation/app_shell_navigation.dart';
import '../../core/notifications/notification_provider.dart';
import '../../core/notifications/budget_settings.dart';
import '../../core/notifications/notification_settings.dart';
import '../../core/preferences/app_preferences.dart';
import '../../core/providers/database_providers.dart';
import '../../core/security/biometric_provider.dart';
import '../../core/security/biometric_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/bangla_formatters.dart';
import '../category/presentation/providers/category_provider.dart';
import '../category/presentation/screens/category_management_screen.dart';
import '../chat/presentation/providers/chat_provider.dart';
import '../chat/data/models/message_model.dart';
import '../anomaly/presentation/providers/anomaly_provider.dart';
import '../budget/domain/entities/budget_plan_entity.dart';
import '../budget/presentation/providers/budget_provider.dart';
import '../budget/presentation/screens/budget_planner_screen.dart';
import '../export/presentation/screens/export_screen.dart';
import '../expense/presentation/providers/expense_providers.dart';
import '../goals/presentation/providers/goal_provider.dart';
import '../goals/presentation/screens/goals_screen.dart';
import '../income/presentation/providers/income_providers.dart';
import '../income/presentation/screens/income_list_screen.dart';
import '../prediction/presentation/providers/prediction_provider.dart';
import '../prediction/data/models/prediction_cache_model.dart';
import '../recurring/presentation/screens/recurring_screen.dart';
import '../wallet/presentation/providers/wallet_provider.dart';
import '../wallet/presentation/screens/wallet_management_screen.dart';
import 'budget_settings_screen.dart';

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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final biometricState = ref.watch(biometricProvider);
    final biometricService = ref.watch(biometricServiceProvider);
    final notificationSettings = ref.watch(notificationProvider);
    final anomalyState = ref.watch(anomalyProvider);
    final goalState = ref.watch(goalProvider);
    final activeBudget = ref.watch(budgetProvider).activeBudget;
    final activeAnomalyCount = anomalyState.activeAlerts.length;
    final activeGoalCount = goalState.activeGoals.length;
    final categories = ref.watch(categoryProvider);
    final categoryNames = categories
        .map((category) => category.name)
        .toList(growable: false);
    final defaultCategory = categoryNames.contains(_defaultCategory)
        ? _defaultCategory
        : 'Other';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SettingsSection(
            title: 'AI Settings',
            children: [
              SwitchListTile.adaptive(
                value: _ragEnabled,
                title: const Text('Personal data use'),
                subtitle: const Text('RAG দিয়ে আপনার খরচের data use হবে'),
                onChanged: (value) async {
                  setState(() {
                    _ragEnabled = value;
                  });
                  ref.read(ragEnabledProvider.notifier).state = value;
                  await AppPreferences.setRagEnabled(value);
                },
              ),
              _DropdownTile(
                title: 'Default category',
                value: defaultCategory,
                items: categoryNames,
                onChanged: (value) async {
                  setState(() {
                    _defaultCategory = value;
                  });
                  await AppPreferences.setDefaultCategory(value);
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'Manage',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.category_outlined),
                title: const Text('Categories'),
                subtitle: const Text('Custom category বানান ও manage করুন'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(buildAppRoute(const CategoryManagementScreen()));
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('ওয়ালেট ম্যানেজমেন্ট'),
                subtitle: const Text(
                  'ক্যাশ, বিকাশ, ব্যাংক একাউন্ট ম্যানেজ করুন',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(buildAppRoute(const WalletManagementScreen()));
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.attach_money),
                title: const Text('আয় ব্যবস্থাপনা'),
                subtitle: const Text('আপনার আয়ের তথ্য দেখুন ও যোগ করুন'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(buildAppRoute(const IncomeListScreen()));
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'Display',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('Theme'),
                trailing: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode, size: 16),
                      label: Text('Light'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto, size: 16),
                      label: Text('Auto'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode, size: 16),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {ref.watch(themeProvider)},
                  onSelectionChanged: (modes) {
                    ref.read(themeProvider.notifier).setTheme(modes.first);
                  },
                ),
              ),
              _DropdownTile(
                title: 'Currency symbol',
                value: _currencySymbol,
                items: _currencyOptions,
                onChanged: (value) async {
                  setState(() {
                    _currencySymbol = value;
                  });
                  await AppPreferences.setCurrencySymbol(value);
                },
              ),
              _DropdownTile(
                title: 'Date format',
                value: _dateFormat,
                items: _dateFormatOptions,
                onChanged: (value) async {
                  setState(() {
                    _dateFormat = value;
                  });
                  await AppPreferences.setDateFormat(value);
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'নিরাপত্তা',
            children: [
              FutureBuilder<bool>(
                future: biometricService.isAvailable(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.fingerprint),
                      title: Text('Biometric lock'),
                      subtitle: Text('Checking availability...'),
                      trailing: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  final isAvailable = snapshot.data ?? false;
                  if (!isAvailable) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      enabled: false,
                      leading: Icon(
                        Icons.fingerprint,
                        color: Theme.of(context).disabledColor,
                      ),
                      title: const Text('Biometric lock'),
                      subtitle: const Text('এই device এ available নেই'),
                    );
                  }

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.fingerprint,
                          color: biometricState.isEnabled
                              ? AppColors.primary
                              : Theme.of(context).disabledColor,
                        ),
                        title: const Text('Biometric lock'),
                        subtitle: Text(
                          biometricState.isEnabled
                              ? 'চালু — app খুলতে verify লাগবে'
                              : 'বন্ধ — সবাই app খুলতে পারবে',
                        ),
                        trailing: Switch.adaptive(
                          value: biometricState.isEnabled,
                          onChanged: (value) => _handleBiometricToggle(value),
                        ),
                      ),
                      if (biometricState.isEnabled)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.timer_outlined),
                          title: const Text('Lock timeout'),
                          subtitle: const Text(
                            'Background এ গেলে কতক্ষণ পরে lock হবে',
                          ),
                          trailing: DropdownButton<int>(
                            value: biometricState.lockTimeoutSeconds,
                            items: _lockTimeoutOptions
                                .map(
                                  (seconds) => DropdownMenuItem<int>(
                                    value: seconds,
                                    child: Text(_lockTimeoutLabel(seconds)),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) {
                              if (value != null) {
                                ref
                                    .read(biometricProvider.notifier)
                                    .setLockTimeout(value);
                              }
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'Notifications',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('Daily reminder'),
                subtitle: Text(
                  notificationSettings.dailyReminderEnabled
                      ? 'খরচ add করার reminder\nপ্রতিদিন ${_formatTimeOfDay(context, notificationSettings.dailyReminderTime)} টায়'
                      : 'খরচ add করার reminder',
                ),
                trailing: Switch.adaptive(
                  value: notificationSettings.dailyReminderEnabled,
                  onChanged: (value) async {
                    if (!value) {
                      await _updateNotificationSettings(
                        notificationSettings.copyWith(
                          dailyReminderEnabled: false,
                        ),
                      );
                      return;
                    }

                    final pickedTime = await _pickReminderTime(
                      notificationSettings.dailyReminderTime,
                    );
                    await _updateNotificationSettings(
                      notificationSettings.copyWith(
                        dailyReminderEnabled: true,
                        dailyReminderTime:
                            pickedTime ??
                            notificationSettings.dailyReminderTime,
                      ),
                    );
                  },
                ),
                onTap: notificationSettings.dailyReminderEnabled
                    ? () => _changeReminderTime(notificationSettings)
                    : null,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.savings_outlined),
                title: const Text('Budget সতর্কতা'),
                subtitle: Text(
                  'Budget এর ${notificationSettings.budgetAlertThreshold.toStringAsFixed(0)}% হলে notify করবে',
                ),
                trailing: Switch.adaptive(
                  value: notificationSettings.budgetAlertEnabled,
                  onChanged: (value) async {
                    await _updateNotificationSettings(
                      notificationSettings.copyWith(budgetAlertEnabled: value),
                    );
                  },
                ),
              ),
              if (notificationSettings.budgetAlertEnabled)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Slider(
                        value: notificationSettings.budgetAlertThreshold,
                        min: 50,
                        max: 100,
                        divisions: 10,
                        label:
                            '${notificationSettings.budgetAlertThreshold.toStringAsFixed(0)}%',
                        onChanged: (value) async {
                          await _updateNotificationSettings(
                            notificationSettings.copyWith(
                              budgetAlertThreshold: value,
                            ),
                          );
                        },
                      ),
                      Text(
                        'Threshold: ${notificationSettings.budgetAlertThreshold.toStringAsFixed(0)}%',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bar_chart_outlined),
                title: const Text('সাপ্তাহিক রিপোর্ট'),
                subtitle: const Text('প্রতি রোববার সকাল ৯টায়'),
                trailing: Switch.adaptive(
                  value: notificationSettings.weeklyReportEnabled,
                  onChanged: (value) async {
                    await _updateNotificationSettings(
                      notificationSettings.copyWith(weeklyReportEnabled: value),
                    );
                  },
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Category budget set করুন'),
                subtitle: const Text('Budget alert এর জন্য'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(buildAppRoute(const BudgetSettingsScreen()));
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'AI Features',
            children: [
              _ActionTile(
                title: 'AI Budget Planner',
                subtitle: activeBudget != null
                    ? '${BanglaFormatters.currency(activeBudget.monthlyIncome)} আয় · ${activeBudget.budgetRule.label}'
                    : 'Budget তৈরি করুন',
                icon: Icons.account_balance_wallet_outlined,
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(buildAppRoute(const BudgetPlannerScreen()));
                },
              ),
              _ActionTile(
                title: 'Regular Expenses',
                subtitle: 'নিয়মিত খরচ detect করুন',
                icon: Icons.sync_alt_rounded,
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(buildAppRoute(const RecurringScreen()));
                },
              ),
              _ActionTile(
                title: 'Split Bill',
                subtitle: 'বন্ধুদের সাথে bill ভাগ করুন',
                icon: Icons.group_work_rounded,
                onTap: () {
                  Navigator.of(context).pop();
                  AppShellNavigation.openSplit();
                },
              ),
              _ActionTile(
                title: 'Goal Tracking',
                subtitle: activeGoalCount == 0
                    ? 'কোনো লক্ষ্য নেই'
                    : '$activeGoalCountটি চলমান লক্ষ্য',
                icon: Icons.flag_outlined,
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(buildAppRoute(const GoalsScreen()));
                },
              ),
              _ActionTile(
                title: 'Spending Alerts',
                subtitle: activeAnomalyCount > 0
                    ? '$activeAnomalyCount টি alert আছে'
                    : 'সব স্বাভাবিক',
                icon: Icons.warning_amber_rounded,
                trailing: activeAnomalyCount > 0
                    ? _CountBadge(count: activeAnomalyCount)
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  AppShellNavigation.openAnalytics(tabIndex: 1);
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'Data',
            children: [
              _ActionTile(
                title: 'Data export',
                subtitle: 'CSV format এ export করুন',
                icon: Icons.download_outlined,
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(buildAppRoute(const ExportScreen()));
                },
              ),
              _ActionTile(
                title: 'Clear all data',
                subtitle: 'সব expense permanently remove হবে',
                icon: Icons.delete_outline_rounded,
                accentColor: AppColors.error,
                onTap: _clearAllData,
              ),
              _ActionTile(
                title: 'Seed demo data',
                subtitle: 'ডেমো expense data add করুন',
                icon: Icons.auto_awesome_outlined,
                onTap: _seedDemoData,
              ),
            ],
          ),
          _SettingsSection(
            title: 'About',
            children: [
              ListTile(
                title: const Text('App version'),
                subtitle: Text(_version),
                contentPadding: EdgeInsets.zero,
              ),
              const ListTile(
                title: Text(AppStrings.poweredBy),
                subtitle: Text('GPT-4o mini · Whisper · ML Kit OCR'),
                contentPadding: EdgeInsets.zero,
              ),
              _ActionTile(
                title: 'GitHub link',
                subtitle: 'Copy repository link',
                icon: Icons.link_rounded,
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
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('সব data clear করবেন?'),
          content: const Text('Chat history আর expense data দুটোই মুছে যাবে।'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(isarProvider).writeTxn(() async {
      await ref.read(isarProvider).expenseRecordModels.clear();
      await ref.read(isarProvider).incomeRecordModels.clear();
      await ref.read(isarProvider).messageModels.clear();
      await ref.read(isarProvider).walletModels.clear();
      await ref.read(isarProvider).budgetPlanModels.clear();
      await ref.read(isarProvider).goalModels.clear();
      await ref.read(isarProvider).goalSavingModels.clear();
      await ref.read(isarProvider).predictionCacheModels.clear();
      await ref.read(isarProvider).recurringExpenseModels.clear();
      await ref.read(isarProvider).splitBillModels.clear();
    });

    await ref.read(predictionProvider.notifier).reset();
    await ref.read(anomalyProvider.notifier).clear();
    await AppPreferences.setActiveWalletId(0);
    await ref.read(budgetSettingsProvider.notifier).clearBudgets();
    ref.read(expenseRefreshTokenProvider.notifier).state++;
    ref.read(incomeRefreshTokenProvider.notifier).state++;
    ref.read(anomalyForceRedetectTokenProvider.notifier).state++;
    ref.read(predictionRefreshTokenProvider.notifier).state++;
    ref.invalidate(budgetProvider);
    ref.invalidate(goalsProvider);
    ref.invalidate(walletProvider);
    ref.invalidate(dashboardControllerProvider);
    ref.invalidate(expenseListControllerProvider);
    ref.invalidate(analyticsControllerProvider);
    ref.invalidate(incomeListControllerProvider);
    ref.invalidate(cashFlowProvider);
    ref.invalidate(thisMonthIncomeProvider);
    ref.invalidate(lastMonthIncomeProvider);
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
    await ref.read(predictionProvider.notifier).reset();
    await ref.read(anomalyProvider.notifier).clear();
    ref.read(expenseRefreshTokenProvider.notifier).state++;
    ref.read(anomalyForceRedetectTokenProvider.notifier).state++;
    ref.read(predictionRefreshTokenProvider.notifier).state++;
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
            value ? 'Biometric lock চালু হয়েছে' : 'Biometric lock বন্ধ হয়েছে',
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
      BiometricAuthResult.notAvailable => 'Biometric available নেই',
      BiometricAuthResult.lockedOut => 'অনেকবার fail — পরে চেষ্টা করুন',
      BiometricAuthResult.failed => 'Verify করা যায়নি',
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
          title: const Text('Biometric set করা নেই'),
          content: const Text(
            'আপনার device এ কোনো fingerprint/face set করা নেই। Settings → Security থেকে set করুন।',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('বাদ দিন'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await openAppSettings();
              },
              child: const Text('Settings এ যান'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeReminderTime(
    NotificationSettings notificationSettings,
  ) async {
    final pickedTime = await _pickReminderTime(
      notificationSettings.dailyReminderTime,
    );
    if (pickedTime == null) {
      return;
    }

    await _updateNotificationSettings(
      notificationSettings.copyWith(dailyReminderTime: pickedTime),
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

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  const _DropdownTile({
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String title;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: title),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.accentColor = AppColors.primary,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color accentColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: accentColor.withValues(alpha: 0.12),
        child: Icon(icon, color: accentColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
