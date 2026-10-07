import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gemini_chat/core/analytics/analytics_providers.dart';
import 'package:gemini_chat/core/analytics/usage_analytics.dart';
import 'package:gemini_chat/core/auth/google_auth_models.dart';
import 'package:gemini_chat/core/auth/google_auth_provider.dart';
import 'package:gemini_chat/core/backup/backup_models.dart';
import 'package:gemini_chat/core/backup/backup_providers.dart';
import 'package:gemini_chat/core/backup/backup_reminder_policy.dart';
import 'package:gemini_chat/core/backup/backup_reminder_provider.dart';
import 'package:gemini_chat/core/network/connectivity_provider.dart';
import 'package:gemini_chat/core/network/connectivity_service.dart';
import 'package:gemini_chat/core/sms/parsed_transaction.dart';
import 'package:gemini_chat/core/sms/sms_import_entry.dart';
import 'package:gemini_chat/core/sms/sms_message.dart';
import 'package:gemini_chat/core/theme/app_theme.dart';
import 'package:gemini_chat/features/anomaly/domain/entities/anomaly_alert.dart';
import 'package:gemini_chat/features/anomaly/presentation/providers/anomaly_provider.dart';
import 'package:gemini_chat/features/budget/domain/entities/budget_plan_entity.dart';
import 'package:gemini_chat/features/budget/presentation/providers/budget_provider.dart';
import 'package:gemini_chat/features/debt/domain/entities/debt_entity.dart';
import 'package:gemini_chat/features/debt/presentation/providers/debt_providers.dart';
import 'package:gemini_chat/features/expense/domain/entities/dashboard_data.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_entity.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_source.dart';
import 'package:gemini_chat/features/expense/presentation/providers/expense_providers.dart';
import 'package:gemini_chat/features/expense/presentation/screens/dashboard_screen.dart';
import 'package:gemini_chat/features/goals/domain/entities/goal_entity.dart';
import 'package:gemini_chat/features/goals/presentation/providers/goal_provider.dart';
import 'package:gemini_chat/features/income/domain/entities/income_entity.dart';
import 'package:gemini_chat/features/income/presentation/providers/income_providers.dart';
import 'package:gemini_chat/features/obligations/presentation/providers/upcoming_obligations_provider.dart';
import 'package:gemini_chat/features/prediction/domain/entities/prediction_entity.dart';
import 'package:gemini_chat/features/prediction/presentation/providers/prediction_provider.dart';
import 'package:gemini_chat/features/recurring/domain/entities/recurring_expense_entity.dart';
import 'package:gemini_chat/features/recurring/presentation/providers/recurring_provider.dart';
import 'package:gemini_chat/features/sms_import/domain/entities/sms_permission_state.dart';
import 'package:gemini_chat/features/sms_import/presentation/models/sms_import_models.dart';
import 'package:gemini_chat/features/sms_import/presentation/providers/sms_import_provider.dart';
import 'package:gemini_chat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:gemini_chat/features/wallet/presentation/providers/wallet_provider.dart';

/// The fixed "today" every Home scenario is rendered at.
final homeToday = DateTime(2026, 10, 6, 9, 30);

/// Everything the Home screen reads, as plain data. Two ready-made states:
/// [HomeScenario.populated] and [HomeScenario.empty].
class HomeScenario {
  const HomeScenario({
    this.thisMonth = 0,
    this.lastMonth = 0,
    this.lastMonthSamePeriod = 0,
    this.monthIncome = 0,
    this.expenses = const [],
    this.incomes = const [],
    this.wallets = const [],
    this.budget,
    this.recurring = const [],
    this.debts = const [],
    this.goals = const [],
    this.prediction,
    this.alerts = const [],
    this.smsEnabled = false,
    this.smsPending = 0,
    this.restoreBackup,
    this.reminder,
    this.signedInName,
  });

  final double thisMonth;
  final double lastMonth;

  /// Last month's day 1..N (what the delta chip compares against).
  final double lastMonthSamePeriod;

  /// This month's income, for the "আয় · নিট" line.
  final double monthIncome;
  final List<ExpenseEntity> expenses;
  final List<IncomeEntity> incomes;
  final List<WalletEntity> wallets;
  final BudgetPlanEntity? budget;
  final List<RecurringExpenseEntity> recurring;
  final List<DebtEntity> debts;
  final List<GoalEntity> goals;
  final PredictionEntity? prediction;
  final List<AnomalyAlert> alerts;
  final bool smsEnabled;
  final int smsPending;
  final BackupFileInfo? restoreBackup;
  final BackupReminderDecision? reminder;
  final String? signedInName;

  static HomeScenario populated({
    String? name = 'Khokan',
    int smsPending = 3,
    BackupReminderDecision? reminder,
    BackupFileInfo? restoreBackup,
    List<AnomalyAlert>? alerts,
  }) {
    final d = homeToday;
    return HomeScenario(
      thisMonth: 41890,
      // Last month's FULL total is far bigger than its same-period total: the chip
      // must use the latter (20% less, not 57% less).
      lastMonth: 98000,
      lastMonthSamePeriod: 52300,
      monthIncome: 65000,
      wallets: [
        _wallet(1, 'নগদ টাকা', WalletType.cash, 12450, 0),
        _wallet(2, 'বিকাশ', WalletType.bkash, 8300, 1),
        _wallet(3, 'নগদ', WalletType.nagad, 2335.5, 2),
        _wallet(4, 'ব্র্যাক ব্যাংক', WalletType.bank, 114900, 3),
      ],
      expenses: [
        _expense(
          'Uber',
          'Transport',
          380,
          d.subtract(const Duration(hours: 2)),
        ),
        _expense(
          'বাড়িভাড়া',
          'Housing',
          15000,
          d.subtract(const Duration(days: 1)),
        ),
        _expense(
          'City Bank',
          'EMI',
          5000,
          d.subtract(const Duration(days: 2)),
          source: ExpenseSource.debtPayment,
        ),
        _expense(
          'ইফতার বাজার',
          'Food',
          1250,
          d.subtract(const Duration(days: 3)),
        ),
        _expense(
          'মোবাইল রিচার্জ',
          'Bills',
          300,
          d.subtract(const Duration(days: 4)),
        ),
      ],
      incomes: [
        IncomeEntity(
          amount: 65000,
          source: 'Salary',
          description: 'অক্টোবরের বেতন',
          date: d.subtract(const Duration(days: 1, hours: 1)),
          createdAt: d,
        ),
      ],
      budget: BudgetPlanEntity(
        id: 1,
        monthlyIncome: 65000,
        categoryBudgets: const {},
        totalBudgeted: 60000,
        savingsAmount: 5000,
        savingsPercentage: 8,
        aiExplanation: '',
        budgetRule: BudgetRule.fiftyThirtyTwenty,
        createdAt: d,
        updatedAt: d,
        isActive: true,
      ),
      recurring: [
        RecurringExpenseEntity(
          id: 1,
          description: 'বাড়িভাড়া',
          category: 'Housing',
          averageAmount: 15000,
          confidenceScore: 1,
          frequency: RecurringFrequency.monthly,
          dayOfMonth: 16,
          dayOfWeek: 3,
          lastOccurrence: DateTime(2026, 9, 16),
          nextExpected: DateTime(2026, 10, 16),
          isActive: true,
          reminderEnabled: false,
        ),
      ],
      debts: [
        DebtEntity(
          id: 1,
          personName: 'City Bank',
          type: DebtType.iOwe,
          originalAmount: 60000,
          remainingAmount: 50000,
          status: DebtStatus.active,
          createdAt: DateTime(2026, 1, 1),
          isEMI: true,
          emiAmount: 5000,
          totalInstallments: 12,
          paidInstallments: 2,
          nextInstallmentDate: DateTime(2026, 10, 10),
        ),
      ],
      prediction: PredictionEntity(
        predictedTotal: 68400,
        currentTotal: 41890,
        lastMonthTotal: 52300,
        dailyAverage: 6981,
        projectedDailyAverage: 6900,
        trend: PredictionTrend.increasing,
        confidence: PredictionConfidence.medium,
        categoryPredictions: const {},
        aiInsight: '',
        generatedAt: d,
        currentDay: 6,
        daysInMonth: 31,
        daysRemaining: 25,
      ),
      alerts:
          alerts ??
          [
            AnomalyAlert(
              id: 1,
              type: AnomalyType.largeTransaction,
              severity: AnomalySeverity.high,
              category: 'Shopping',
              currentAmount: 9800,
              normalAmount: 2000,
              ratio: 4.9,
              message: '',
              detectedAt: d,
            ),
          ],
      smsEnabled: true,
      smsPending: smsPending,
      reminder: reminder,
      restoreBackup: restoreBackup,
      signedInName: name,
    );
  }

  /// Zero expenses AND zero income: the first-run state.
  static HomeScenario empty({
    bool smsEnabled = false,
    BackupFileInfo? restoreBackup,
  }) {
    return HomeScenario(
      wallets: [_wallet(1, 'নগদ টাকা', WalletType.cash, 0, 0)],
      smsEnabled: smsEnabled,
      restoreBackup: restoreBackup,
    );
  }
}

WalletEntity _wallet(
  int id,
  String name,
  WalletType type,
  double balance,
  int order,
) {
  final now = DateTime(2026, 10, 1);
  return WalletEntity(
    id: id,
    name: name,
    type: type,
    emoji: type.defaultEmoji,
    initialBalance: 0,
    currentBalance: balance,
    accountNumber: null,
    note: null,
    sortOrder: order,
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );
}

ExpenseEntity _expense(
  String description,
  String category,
  double amount,
  DateTime date, {
  ExpenseSource source = ExpenseSource.expense,
}) {
  return ExpenseEntity(
    id: description.hashCode & 0xffff,
    amount: amount,
    category: category,
    description: description,
    date: date,
    sourceType: source,
  );
}

SmsImportEntry _pending(int i) {
  final at = homeToday.subtract(Duration(hours: i + 1));
  return SmsImportEntry(
    signature: 'sig-$i',
    sms: SmsMessage(
      id: 900 + i,
      address: 'bKash',
      body: 'Payment $i',
      date: at,
    ),
    transaction: ParsedTransaction(
      smsId: 900 + i,
      sender: 'bKash',
      source: ParsedTransactionSource.bkash,
      direction: ParsedTransactionDirection.debit,
      kind: ParsedTransactionKind.payment,
      amount: 100.0 * (i + 1),
      rawMessage: 'Payment $i',
      receivedAt: at,
      occurredAt: at,
      counterparty: 'Shop $i',
      confidence: 1,
    ),
    detectedAt: at,
  );
}

class _FakeDashboard extends DashboardController {
  _FakeDashboard(this.s);
  final HomeScenario s;
  @override
  Future<DashboardData> build() async => DashboardData(
    thisMonthTotal: s.thisMonth,
    lastMonthTotal: s.lastMonth,
    thisMonthToDateTotal: s.thisMonth,
    lastMonthSamePeriodTotal: s.lastMonthSamePeriod,
    thisWeekTotal: 0,
    transactionCount: s.expenses.length,
    manualEntryCount: 0,
    categoryTotals: const {},
    todayExpenses: const [],
    recentExpenses: s.expenses,
  );
}

class _FakeIncome extends IncomeListController {
  _FakeIncome(this.items);
  final List<IncomeEntity> items;
  @override
  Future<List<IncomeEntity>> build() async => items;
}

class _FakeWallets extends WalletNotifier {
  _FakeWallets(this.items);
  final List<WalletEntity> items;
  @override
  Future<List<WalletEntity>> build() async => items;
}

class _FakeBudget extends BudgetNotifier {
  _FakeBudget(this.plan);
  final BudgetPlanEntity? plan;
  @override
  BudgetState build() => BudgetState(activeBudget: plan);
}

class _FakePrediction extends PredictionNotifier {
  _FakePrediction(this.p);
  final PredictionEntity? p;
  @override
  PredictionState build() => PredictionState(prediction: p);
}

class _FakeAnomaly extends AnomalyNotifier {
  _FakeAnomaly(this.alerts);
  final List<AnomalyAlert> alerts;
  @override
  AnomalyState build() => AnomalyState(alerts: alerts, isDetecting: false);
}

class _FakeSms extends SmsAutoImportNotifier {
  _FakeSms({required this.enabled, required this.pending});
  final bool enabled;
  final int pending;
  @override
  SmsAutoImportState build() => SmsAutoImportState(
    permissionState: enabled
        ? SmsPermissionState.granted
        : SmsPermissionState.denied,
    isEnabled: enabled,
    isListening: false,
    autoConfirm: false,
    importedCount: 0,
    pendingTransactions: [for (var i = 0; i < pending; i++) _pending(i)],
    enabledSources: const [],
    isBusy: false,
    isRescanning: false,
  );
}

class _FakeAuth extends GoogleAuthNotifier {
  _FakeAuth(this.name);
  final String? name;
  @override
  GoogleAuthState build() => GoogleAuthState(
    isLoading: false,
    isBusy: false,
    session: name == null
        ? null
        : GoogleAuthSession(
            id: 'u1',
            email: 'u@example.com',
            displayName: '$name Uddin',
          ),
  );
}

class _FakeRecurring extends RecurringNotifier {
  _FakeRecurring(this.items);
  final List<RecurringExpenseEntity> items;
  @override
  Future<List<RecurringExpenseEntity>> build() async => items;
}

class _FakeGoals extends GoalNotifier {
  _FakeGoals(this.items);
  final List<GoalEntity> items;
  @override
  GoalState build() => GoalState(goals: items, isLoading: false);
}

class _FakeDebts extends DebtListNotifier {
  _FakeDebts(this.items);
  final List<DebtEntity> items;
  @override
  Future<DebtListState> build() async =>
      DebtListState(debts: items, filter: DebtFilterType.all);
}

class _OfflineSafeConnectivity implements ConnectivityService {
  @override
  Future<bool> isConnected() async => true;
  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

class RecordingAnalyticsLogger implements AnalyticsLogger {
  final events = <String>[];
  final params = <Map<String, Object>?>[];
  @override
  Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    events.add(name);
    params.add(parameters);
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

List<Override> homeOverrides(
  HomeScenario s, {
  RecordingAnalyticsLogger? logger,
}) {
  return [
    obligationsClockProvider.overrideWithValue(() => homeToday),
    dashboardControllerProvider.overrideWith(() => _FakeDashboard(s)),
    incomeListControllerProvider.overrideWith(() => _FakeIncome(s.incomes)),
    walletProvider.overrideWith(() => _FakeWallets(s.wallets)),
    budgetProvider.overrideWith(() => _FakeBudget(s.budget)),
    predictionProvider.overrideWith(() => _FakePrediction(s.prediction)),
    anomalyProvider.overrideWith(() => _FakeAnomaly(s.alerts)),
    smsAutoImportProvider.overrideWith(
      () => _FakeSms(enabled: s.smsEnabled, pending: s.smsPending),
    ),
    googleAuthProvider.overrideWith(() => _FakeAuth(s.signedInName)),
    recurringProvider.overrideWith(() => _FakeRecurring(s.recurring)),
    debtListProvider.overrideWith(() => _FakeDebts(s.debts)),
    goalProvider.overrideWith(() => _FakeGoals(s.goals)),
    cashFlowProvider.overrideWith(
      (ref) async => CashFlowData(
        income: s.monthIncome,
        expense: s.thisMonth,
        lastMonthIncome: 0,
        lastMonthExpense: s.lastMonth,
      ),
    ),
    restorePromptProvider.overrideWith((ref) => s.restoreBackup),
    backupReminderProvider.overrideWith((ref) async => s.reminder),
    connectivityServiceProvider.overrideWithValue(_OfflineSafeConnectivity()),
    usageAnalyticsProvider.overrideWithValue(
      UsageAnalytics(logger ?? RecordingAnalyticsLogger(), enabled: true),
    ),
  ];
}

/// The Home screen under a scenario, theme and text scale.
Widget homeApp(
  HomeScenario scenario, {
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
  RecordingAnalyticsLogger? logger,
  Widget? home,
}) {
  return ProviderScope(
    overrides: homeOverrides(scenario, logger: logger),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.dark
          ? AppTheme.darkTheme()
          : AppTheme.lightTheme(),
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
      home: home ?? const DashboardScreen(),
    ),
  );
}
