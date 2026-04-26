import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gemini_chat/core/network/connectivity_provider.dart';
import 'package:gemini_chat/core/network/connectivity_service.dart';
import 'package:gemini_chat/core/premium/premium_providers.dart';
import 'package:gemini_chat/core/premium/premium_service.dart';
import 'package:gemini_chat/core/providers/shared_preferences_provider.dart';
import 'package:gemini_chat/core/usage/usage_gate_result.dart';
import 'package:gemini_chat/core/usage/usage_limits.dart';
import 'package:gemini_chat/core/usage/usage_providers.dart';
import 'package:gemini_chat/core/usage/usage_status.dart';
import 'package:gemini_chat/core/usage/usage_tracker_service.dart';
import 'package:gemini_chat/features/budget/data/datasources/budget_planner_datasource.dart';
import 'package:gemini_chat/features/budget/domain/entities/budget_plan_entity.dart';
import 'package:gemini_chat/features/budget/domain/repositories/budget_repository.dart';
import 'package:gemini_chat/features/budget/presentation/providers/budget_provider.dart';
import 'package:gemini_chat/features/category/domain/entities/category_entity.dart';
import 'package:gemini_chat/features/category/presentation/providers/category_provider.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_entity.dart';
import 'package:gemini_chat/features/expense/domain/repositories/expense_repository.dart';
import 'package:gemini_chat/features/expense/presentation/providers/expense_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Budget usage gates', () {
    test('free users are blocked after monthly AI budget limit', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final usageService = _FakeUsageTrackerService(
        results: {
          UsageLimits.aiBudget: UsageGateResult.blocked(
            UsageStatus(
              feature: UsageLimits.aiBudget,
              used: 3,
              limit: 3,
              isMonthly: true,
              resetAt: DateTime(2026, 5, 1),
            ),
          ),
        },
      );
      final planner = _FakeBudgetPlannerDataSource();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          budgetRepositoryProvider.overrideWithValue(_FakeBudgetRepository()),
          budgetPlannerDataSourceProvider.overrideWithValue(planner),
          expenseRepositoryProvider.overrideWithValue(_FakeExpenseRepository()),
          categoryProvider.overrideWith(_TestCategoryNotifier.new),
          connectivityServiceProvider.overrideWithValue(
            _FakeConnectivityService(),
          ),
          usageTrackerServiceProvider.overrideWithValue(usageService),
          premiumServiceProvider.overrideWithValue(
            _FakePremiumService(isPremiumUser: false),
          ),
          isPremiumProvider.overrideWith((ref) => false),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(budgetProvider.notifier);
      notifier.setIncome(50000);
      await Future<void>.delayed(Duration.zero);

      await notifier.generateBudget();

      final state = container.read(budgetProvider);
      expect(planner.generateCalls, 0);
      expect(
        state.error,
        'এই মাসের AI বাজেট সীমা শেষ (3/3 ব্যবহার হয়েছে). প্রিমিয়াম এ আপগ্রেড করুন।',
      );
      expect(container.read(usageRefreshTokenProvider), 0);
    });

    test('premium users bypass monthly AI budget limit', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final usageService = _FakeUsageTrackerService(
        results: {
          UsageLimits.aiBudget: UsageGateResult.blocked(
            UsageStatus(
              feature: UsageLimits.aiBudget,
              used: 3,
              limit: 3,
              isMonthly: true,
              resetAt: DateTime(2026, 5, 1),
            ),
          ),
        },
      );
      final planner = _FakeBudgetPlannerDataSource();
      final repository = _FakeBudgetRepository();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          budgetRepositoryProvider.overrideWithValue(repository),
          budgetPlannerDataSourceProvider.overrideWithValue(planner),
          expenseRepositoryProvider.overrideWithValue(_FakeExpenseRepository()),
          categoryProvider.overrideWith(_TestCategoryNotifier.new),
          connectivityServiceProvider.overrideWithValue(
            _FakeConnectivityService(),
          ),
          usageTrackerServiceProvider.overrideWithValue(usageService),
          premiumServiceProvider.overrideWithValue(
            _FakePremiumService(isPremiumUser: true),
          ),
          isPremiumProvider.overrideWith((ref) => true),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(budgetProvider.notifier);
      notifier.setIncome(50000);
      await Future<void>.delayed(Duration.zero);

      await notifier.generateBudget();

      final state = container.read(budgetProvider);
      expect(planner.generateCalls, 1);
      expect(usageService.checkCalls, isEmpty);
      expect(state.error, isNull);
      expect(repository.savedBudgets, isNotEmpty);
    });
  });
}

class _FakeBudgetPlannerDataSource extends BudgetPlannerDataSource {
  _FakeBudgetPlannerDataSource()
    : super(connectivityService: _FakeConnectivityService());

  int generateCalls = 0;

  @override
  Stream<String> generateBudget({
    required double monthlyIncome,
    required Map<String, double> avgMonthlyByCategory,
    required List<String> availableCategories,
    required BudgetRule preferredRule,
  }) async* {
    generateCalls++;
    yield '''
{
  "rule": "fiftyThirtyTwenty",
  "categoryBudgets": {
    "Food": 15000,
    "Transport": 5000
  },
  "totalBudgeted": 20000,
  "savingsAmount": 30000,
  "savingsPercentage": 60
}
এই পরিকল্পনায় খরচ নিয়ন্ত্রিত থাকবে।
''';
  }
}

class _FakeBudgetRepository implements BudgetRepository {
  final List<BudgetPlanEntity> savedBudgets = [];

  @override
  Future<void> deactivateAll() async {
    for (var index = 0; index < savedBudgets.length; index++) {
      savedBudgets[index] = savedBudgets[index].copyWith(isActive: false);
    }
  }

  @override
  Future<void> deleteBudget(int id) async {
    savedBudgets.removeWhere((budget) => budget.id == id);
  }

  @override
  Future<BudgetPlanEntity?> getActiveBudget() async {
    for (final budget in savedBudgets) {
      if (budget.isActive) {
        return budget;
      }
    }
    return null;
  }

  @override
  Future<List<BudgetPlanEntity>> getAllBudgets() async => List.of(savedBudgets);

  @override
  Future<void> saveBudget(BudgetPlanEntity plan) async {
    savedBudgets.add(plan);
  }

  @override
  Future<void> setActiveBudget(int id) async {
    for (var index = 0; index < savedBudgets.length; index++) {
      savedBudgets[index] = savedBudgets[index].copyWith(
        isActive: savedBudgets[index].id == id,
      );
    }
  }

  @override
  Future<void> updateBudget(BudgetPlanEntity plan) async {
    final index = savedBudgets.indexWhere((budget) => budget.id == plan.id);
    if (index >= 0) {
      savedBudgets[index] = plan;
    }
  }
}

class _FakeExpenseRepository implements ExpenseRepository {
  @override
  Future<void> deleteExpense(int id) async {}

  @override
  Future<List<ExpenseEntity>> getAllExpenses() async => const [];

  @override
  Future<Map<String, double>> getCategoryTotals(
    DateTime start,
    DateTime end,
  ) async => const {};

  @override
  Future<Map<DateTime, double>> getDailyTotals(int days) async => const {};

  @override
  Future<List<ExpenseEntity>> getExpensesByCategory(String category) async =>
      const [];

  @override
  Future<List<ExpenseEntity>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async => const [];

  @override
  Future<List<ExpenseEntity>> getExpensesByWallet(int walletId) async =>
      const [];

  @override
  Future<List<ExpenseEntity>> getExpensesForMonth(DateTime month) async =>
      const [];

  @override
  Future<List<ExpenseEntity>> getLastMonthExpenses() async => const [];

  @override
  Future<List<ExpenseEntity>> getThisMonthExpenses() async => const [];

  @override
  Future<List<ExpenseEntity>> getTodayExpenses() async => const [];

  @override
  Future<ExpenseEntity> saveExpense(ExpenseEntity expense) async => expense;

  @override
  Future<List<ExpenseEntity>> saveExpenses(
    List<ExpenseEntity> expenses,
  ) async => expenses;

  @override
  Future<void> updateExpense(ExpenseEntity expense) async {}
}

class _FakeConnectivityService extends ConnectivityService {
  @override
  Future<bool> isConnected() async => true;

  @override
  Stream<bool> get onConnectivityChanged => const Stream<bool>.empty();
}

class _TestCategoryNotifier extends CategoryNotifier {
  @override
  List<CategoryEntity> build() {
    return [
      CategoryEntity(
        id: 1,
        name: 'Food',
        icon: 'restaurant',
        colorValue: 0xFFFF6D00,
        isDefault: true,
        sortOrder: 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      ),
      CategoryEntity(
        id: 2,
        name: 'Transport',
        icon: 'directions_car',
        colorValue: 0xFF1A73E8,
        isDefault: true,
        sortOrder: 2,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      ),
    ];
  }
}

class _FakeUsageTrackerService implements UsageTrackerService {
  _FakeUsageTrackerService({required this.results});

  final Map<String, UsageGateResult> results;
  final List<String> checkCalls = [];

  @override
  FirebaseAuth get firebaseAuth => throw UnimplementedError();

  @override
  FirebaseFirestore get firestore => throw UnimplementedError();

  @override
  SharedPreferences get prefs => throw UnimplementedError();

  @override
  Future<UsageGateResult> checkAndConsume(String feature) async {
    checkCalls.add(feature);
    return results[feature] ??
        UsageGateResult.allowed(
          UsageStatus(
            feature: feature,
            used: 1,
            limit: UsageLimits.limitFor(feature),
            isMonthly: UsageLimits.isMonthly(feature),
            resetAt: DateTime(2026, 5, 1),
          ),
        );
  }

  @override
  Future<Map<String, UsageStatus>> getAllStatuses() async => const {};

  @override
  Future<int> getCount(String feature) async => 0;

  @override
  Future<UsageStatus> getStatus(String feature) async => UsageStatus(
    feature: feature,
    used: 0,
    limit: UsageLimits.limitFor(feature),
    isMonthly: UsageLimits.isMonthly(feature),
    resetAt: DateTime(2026, 5, 1),
  );

  @override
  Future<bool> hasReachedLimit(String feature) async =>
      !(results[feature]?.isAllowed ?? true);

  @override
  Future<void> increment(String feature) async {}

  @override
  Future<void> syncFromFirestore() async {}
}

class _FakePremiumService implements PremiumService {
  _FakePremiumService({required this.isPremiumUser});

  final bool isPremiumUser;

  @override
  RevenueCatKeyMode get keyMode => RevenueCatKeyMode.production;

  @override
  bool get isUsingTestStore => false;

  @override
  bool get hasUsableSdkKey => true;

  @override
  String? get configurationWarningBn => null;

  @override
  void setMockPremium(bool enabled) {}

  @override
  Future<PremiumStatus> getStatus() async => isPremiumUser
      ? const PremiumStatus(isPremium: true, activeProductId: 'premium_yearly')
      : const PremiumStatus.free();

  @override
  Future<List<PremiumPackage>> getOfferings() async => const [];

  @override
  Future<void> initialize({String? userId}) async {}

  @override
  Future<bool> isPremium() async => isPremiumUser;

  @override
  Future<PurchaseResult> purchase(PremiumPackage package) async =>
      const PurchaseResult.error('unused');

  @override
  Future<PurchaseResult> restorePurchases() async =>
      const PurchaseResult.error('unused');

  @override
  Future<void> syncUserId(String? userId) async {}
}
