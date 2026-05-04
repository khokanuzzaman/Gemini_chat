import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_strings.dart';
import 'core/backup/backup_orchestrator.dart';
import 'core/backup/backup_providers.dart';
import 'core/database/expense_migration.dart';
import 'core/database/models/expense_record_model.dart';
import 'core/database/models/imported_sms_model.dart';
import 'core/database/models/income_record_model.dart';
import 'core/database/models/budget_plan_model.dart';
import 'core/database/models/goal_model.dart';
import 'core/database/models/goal_saving_model.dart';
import 'core/database/models/recurring_expense_model.dart';
import 'core/database/models/sms_ledger_entry_model.dart';
import 'core/database/models/sms_ledger_sync_state_model.dart';
import 'core/database/models/split_bill_model.dart';
import 'core/database/models/wallet_model.dart';
import 'features/prediction/data/models/prediction_cache_model.dart';
import 'core/navigation/app_shell_navigation.dart';
import 'core/notifications/notification_provider.dart';
import 'core/notifications/notification_service.dart';
import 'core/preferences/app_preferences.dart';
import 'core/premium/premium_providers.dart';
import 'core/premium/premium_service.dart';
import 'core/providers/database_providers.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'core/security/app_lifecycle_observer.dart';
import 'core/security/biometric_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/usage/usage_limits.dart';
import 'features/chat/data/models/message_model.dart';
import 'features/category/data/datasources/category_local_datasource.dart';
import 'features/category/data/models/category_model.dart';
import 'features/debt/data/models/debt_model.dart';
import 'features/debt/data/models/debt_payment_model.dart';
import 'features/category/domain/category_registry.dart';
import 'features/chat/presentation/providers/chat_provider.dart';
import 'features/anomaly/presentation/providers/anomaly_provider.dart';
import 'features/chat/presentation/screens/chat_screen.dart';
import 'features/expense/presentation/providers/expense_providers.dart';
import 'features/expense/presentation/screens/analytics_screen.dart';
import 'features/expense/presentation/screens/dashboard_screen.dart';
import 'features/expense/presentation/screens/expense_list_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/security/lock_screen.dart';
import 'features/sms_import/presentation/providers/sms_import_provider.dart';
import 'features/split/presentation/screens/split_bill_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/wallet/data/datasources/wallet_local_datasource.dart';
import 'features/wallet/presentation/providers/wallet_provider.dart';
import 'core/usage/usage_providers.dart';

const _notificationPermissionAskedKey = 'notification_permission_asked';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('bn');
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp();
  final premiumService = PremiumService(
    firebaseAuth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
  await premiumService.initialize(
    userId: FirebaseAuth.instance.currentUser?.uid,
  );
  final sharedPreferences = await SharedPreferences.getInstance();
  final savedThemeMode = await _loadSavedThemeMode();

  await NotificationService.initialize();

  final notifAsked =
      sharedPreferences.getBool(_notificationPermissionAskedKey) ?? false;
  if (!notifAsked) {
    await NotificationService.requestPermission();
    await sharedPreferences.setBool(_notificationPermissionAskedKey, true);
  }

  final isar = await _openIsar();
  final categoryLocalDataSource = CategoryLocalDataSource(isar);
  await categoryLocalDataSource.seedDefaultCategories();
  final walletLocalDataSource = WalletLocalDataSource(isar);
  await walletLocalDataSource.seedDefaultWallets();
  await ExpenseMigration.migrateExpensesToDefaultWallet(
    isar: isar,
    prefs: sharedPreferences,
  );
  final bootCategories = await categoryLocalDataSource.getAllCategories();
  CategoryRegistry.setCategories(
    bootCategories
        .map((category) => category.toEntity())
        .toList(growable: false),
  );

  final bootstrapContainer = ProviderContainer(
    overrides: [
      isarProvider.overrideWithValue(isar),
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      premiumServiceProvider.overrideWithValue(premiumService),
    ],
  );
  await bootstrapContainer
      .read(notificationProvider.notifier)
      .reapplyCurrentSettings();
  unawaited(() async {
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        await bootstrapContainer
            .read(usageTrackerServiceProvider)
            .syncFromFirestore();
      }
      await _checkAutoBackup(bootstrapContainer);
    } finally {
      bootstrapContainer.dispose();
    }
  }());

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        themeBootstrapProvider.overrideWithValue(savedThemeMode),
        premiumServiceProvider.overrideWithValue(premiumService),
      ],
      child: const ExpenseTrackerApp(),
    ),
  );
}

Future<ThemeMode> _loadSavedThemeMode() async {
  final savedTheme = await AppPreferences.themeMode();
  return switch (savedTheme) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

Future<void> _checkAutoBackup(ProviderContainer container) async {
  try {
    final prefs = container.read(sharedPreferencesProvider);
    final isEnabled =
        prefs.getBool(BackupOrchestrator.autoBackupEnabledKey) ?? false;
    if (!isEnabled) {
      return;
    }

    final lastBackupMs = prefs.getInt(BackupOrchestrator.backupLastTimeKey);
    if (lastBackupMs != null && lastBackupMs > 0) {
      final lastBackup = DateTime.fromMillisecondsSinceEpoch(lastBackupMs);
      if (DateTime.now().difference(lastBackup) < const Duration(hours: 24)) {
        return;
      }
    }

    final auth = container.read(googleAuthServiceProvider);
    if (!await auth.isSignedIn()) {
      await auth.signInSilently();
      if (!await auth.isSignedIn()) {
        return;
      }
    }

    final isPremiumUser = await _isPremiumUser(container);
    if (!isPremiumUser) {
      try {
        final gate = await container
            .read(usageTrackerServiceProvider)
            .checkAndConsume(UsageLimits.cloudBackup);
        if (!gate.isAllowed) {
          return;
        }
      } catch (_) {
        // Usage tracking is best-effort for silent backups.
      }
    }

    await container.read(backupOrchestratorProvider).createBackup();
  } catch (_) {
    // Auto-backup is best-effort; failures are intentionally ignored.
  }
}

Future<bool> _isPremiumUser(ProviderContainer container) async {
  if (container.read(isPremiumProvider)) {
    return true;
  }

  try {
    return await container.read(premiumServiceProvider).isPremium();
  } catch (_) {
    return false;
  }
}

Future<void> _checkForExistingBackup(WidgetRef ref) async {
  try {
    final auth = ref.read(googleAuthServiceProvider);
    await auth.signInSilently();
    if (!await auth.isSignedIn()) {
      return;
    }

    final backup = await ref
        .read(backupOrchestratorProvider)
        .getCloudBackupInfo();
    if (backup != null) {
      ref.read(restorePromptProvider.notifier).state = backup;
    }
  } catch (_) {
    // Restore prompt is opportunistic; failures are intentionally ignored.
  }
}

Future<Isar> _openIsar() async {
  const instanceName = 'pocketpilot_ai';
  final existingInstance = Isar.getInstance(instanceName);
  if (existingInstance != null) {
    return existingInstance;
  }

  final directory = await getApplicationDocumentsDirectory();
  return Isar.open(
    [
      MessageModelSchema,
      ExpenseRecordModelSchema,
      CategoryModelSchema,
      BudgetPlanModelSchema,
      GoalModelSchema,
      GoalSavingModelSchema,
      RecurringExpenseModelSchema,
      SplitBillModelSchema,
      WalletModelSchema,
      ImportedSmsModelSchema,
      SmsLedgerEntryModelSchema,
      SmsLedgerSyncStateModelSchema,
      PredictionCacheModelSchema,
      IncomeRecordModelSchema,
      DebtModelSchema,
      DebtPaymentModelSchema,
    ],
    directory: directory.path,
    name: instanceName,
  );
}

class ExpenseTrackerApp extends ConsumerStatefulWidget {
  const ExpenseTrackerApp({super.key});

  @override
  ConsumerState<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends ConsumerState<ExpenseTrackerApp> {
  late final AppLifecycleObserver _appLifecycleObserver;

  @override
  void initState() {
    super.initState();
    _appLifecycleObserver = AppLifecycleObserver(ref: ref);
    WidgetsBinding.instance.addObserver(_appLifecycleObserver);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(anomalyProvider.notifier).detectIfNeeded();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_appLifecycleObserver);
    _appLifecycleObserver.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final biometric = ref.watch(biometricProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      navigatorKey: AppShellNavigation.navigatorKey,
      locale: const Locale('bn', 'BD'),
      supportedLocales: const [Locale('bn', 'BD'), Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 250),
      themeAnimationCurve: Curves.easeOutCubic,
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            if (biometric.needsUnlock)
              Positioned.fill(child: LockScreen(onUnlocked: () {})),
          ],
        );
      },
      home: const _AppBootstrap(),
    );
  }
}

class _AppBootstrap extends ConsumerStatefulWidget {
  const _AppBootstrap();

  @override
  ConsumerState<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<_AppBootstrap> {
  bool _showSplash = true;
  bool _onboardingComplete = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final onboardingComplete = await AppPreferences.isOnboardingComplete();
    if (!mounted) {
      return;
    }

    if (onboardingComplete) {
      final expenseCount = await ref
          .read(isarProvider)
          .expenseRecordModels
          .count();
      if (!mounted) {
        return;
      }
      if (expenseCount == 0) {
        unawaited(_checkForExistingBackup(ref));
      }
    }
    setState(() {
      _onboardingComplete = onboardingComplete;
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SizedBox.shrink();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: _showSplash
          ? SplashScreen(
              key: const ValueKey('splash'),
              onFinished: () {
                if (!mounted) {
                  return;
                }
                setState(() {
                  _showSplash = false;
                });
              },
            )
          : _onboardingComplete
          ? const _MainShell(key: ValueKey('shell'))
          : OnboardingScreen(
              key: const ValueKey('onboarding'),
              onComplete: () {
                if (!mounted) {
                  return;
                }
                setState(() {
                  _onboardingComplete = true;
                });
              },
            ),
    );
  }
}

class _MainShell extends ConsumerStatefulWidget {
  const _MainShell({super.key});

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  int _currentIndex = 0;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    AppShellNavigation.selectedTab.addListener(_handleExternalTabChange);
    _currentIndex = AppShellNavigation.selectedTab.value;
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      ref.read(premiumStatusProvider.notifier).syncUser(user?.uid);
      if (user != null) {
        ref.read(usageTrackerServiceProvider).syncFromFirestore();
        ref.read(usageRefreshTokenProvider.notifier).state++;
      }
    });
    _hydratePreferences();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    AppShellNavigation.selectedTab.removeListener(_handleExternalTabChange);
    super.dispose();
  }

  Future<void> _hydratePreferences() async {
    final ragEnabled = await AppPreferences.isRagEnabled();
    final activeWalletId = await AppPreferences.activeWalletId();
    if (!mounted) {
      return;
    }
    ref.read(ragEnabledProvider.notifier).state = ragEnabled;
    ref.read(activeWalletIdProvider.notifier).state = activeWalletId;
    ref.read(backupStateProvider);
    ref.read(smsAutoImportProvider);
  }

  @override
  Widget build(BuildContext context) {
    final highSeverityAnomalyCount = ref
        .watch(anomalyProvider)
        .highSeverityCount;
    final screens = [
      DashboardScreen(
        onOpenExpenses: _openExpenses,
        onOpenChat: () => setState(() => _currentIndex = 1),
      ),
      const ChatScreen(),
      const ExpenseListScreen(),
      const AnalyticsScreen(),
      const SplitBillScreen(),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: context.shellBackgroundGradient),
        child: IndexedStack(index: _currentIndex, children: screens),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: context.cardBackgroundColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: context.isDarkMode
                    ? AppColors.darkBackground.withValues(alpha: 0.4)
                    : AppColors.lightText.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: NavigationBar(
            height: 72,
            elevation: 0,
            backgroundColor: Colors.transparent,
            indicatorColor: Colors.transparent,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              _setCurrentIndex(index);
            },
            destinations: [
              NavigationDestination(
                icon: _NavIcon(
                  icon: Icons.home_rounded,
                  label: 'হোম',
                  active: false,
                ),
                selectedIcon: _NavIcon(
                  icon: Icons.home_rounded,
                  label: 'হোম',
                  active: true,
                ),
                label: 'হোম',
              ),
              NavigationDestination(
                icon: _NavIcon(
                  icon: Icons.chat_bubble_rounded,
                  label: 'চ্যাট',
                  active: false,
                ),
                selectedIcon: _NavIcon(
                  icon: Icons.chat_bubble_rounded,
                  label: 'চ্যাট',
                  active: true,
                ),
                label: 'চ্যাট',
              ),
              NavigationDestination(
                icon: _NavIcon(
                  icon: Icons.receipt_long_rounded,
                  label: 'খরচ',
                  active: false,
                ),
                selectedIcon: _NavIcon(
                  icon: Icons.receipt_long_rounded,
                  label: 'খরচ',
                  active: true,
                ),
                label: 'খরচ',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: highSeverityAnomalyCount > 0,
                  backgroundColor: AppColors.error,
                  label: Text(
                    highSeverityAnomalyCount > 9
                        ? '9+'
                        : '$highSeverityAnomalyCount',
                  ),
                  child: const _NavIcon(
                    icon: Icons.bar_chart_rounded,
                    label: 'বিশ্লেষণ',
                    active: false,
                  ),
                ),
                selectedIcon: Badge(
                  isLabelVisible: highSeverityAnomalyCount > 0,
                  backgroundColor: AppColors.error,
                  label: Text(
                    highSeverityAnomalyCount > 9
                        ? '9+'
                        : '$highSeverityAnomalyCount',
                  ),
                  child: const _NavIcon(
                    icon: Icons.bar_chart_rounded,
                    label: 'বিশ্লেষণ',
                    active: true,
                  ),
                ),
                label: 'বিশ্লেষণ',
              ),
              NavigationDestination(
                icon: _NavIcon(
                  icon: Icons.call_split_rounded,
                  label: 'Split',
                  active: false,
                ),
                selectedIcon: _NavIcon(
                  icon: Icons.call_split_rounded,
                  label: 'Split',
                  active: true,
                ),
                label: 'Split',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openExpenses(String? category) async {
    final controller = ref.read(expenseListControllerProvider.notifier);
    await controller.clearFilters();
    if (category != null) {
      await controller.setCategory(category);
    }

    if (!mounted) {
      return;
    }
    _setCurrentIndex(2);
  }

  void _handleExternalTabChange() {
    final nextIndex = AppShellNavigation.selectedTab.value;
    if (!mounted || nextIndex == _currentIndex) {
      return;
    }

    setState(() {
      _currentIndex = nextIndex;
    });
  }

  void _setCurrentIndex(int index) {
    if (!mounted) {
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
    });
    if (AppShellNavigation.selectedTab.value != index) {
      AppShellNavigation.selectedTab.value = index;
    }
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = context.secondaryTextColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedOpacity(
          opacity: active ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: activeColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Icon(icon, color: active ? activeColor : inactiveColor),
      ],
    );
  }
}

// DARK MODE TEST CHECKLIST
// [ ] Chat screen — bubbles readable
// [ ] Dashboard — header card, stat cards
// [ ] Expense list — filter pills, list items
// [ ] Analytics — charts visible
// [ ] RAG widgets — cards readable
// [ ] Confirmation widgets — checkboxes visible
// [ ] Settings — toggle works, saves preference
// [ ] Splash — correct background
// [ ] Onboarding — text readable
// [ ] App restart — theme preference saved
