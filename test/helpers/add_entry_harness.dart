import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gemini_chat/core/analytics/analytics_providers.dart';
import 'package:gemini_chat/core/analytics/usage_analytics.dart';
import 'package:gemini_chat/core/providers/shared_preferences_provider.dart';
import 'package:gemini_chat/core/theme/app_theme.dart';
import 'package:gemini_chat/features/category/domain/entities/category_entity.dart';
import 'package:gemini_chat/features/category/presentation/providers/category_provider.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_entity.dart';
import 'package:gemini_chat/features/expense/presentation/providers/expense_providers.dart';
import 'package:gemini_chat/features/expense/presentation/widgets/add_entry/add_entry_sheet.dart';
import 'package:gemini_chat/features/expense/presentation/widgets/add_entry/entry_type.dart';
import 'package:gemini_chat/features/income/domain/entities/income_entity.dart';
import 'package:gemini_chat/features/income/presentation/providers/income_providers.dart';
import 'package:gemini_chat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:gemini_chat/features/wallet/presentation/providers/wallet_provider.dart';

class MockExpenseMutation extends Mock implements ExpenseMutationController {}

class MockIncomeMutation extends Mock implements IncomeMutationController {}

class _FakeCategories extends CategoryNotifier {
  _FakeCategories(this.items);
  final List<CategoryEntity> items;
  @override
  List<CategoryEntity> build() => items;
}

class _FakeWallets extends WalletNotifier {
  _FakeWallets(this.items);
  final List<WalletEntity> items;
  @override
  Future<List<WalletEntity>> build() async => items;
}

class _Logger implements AnalyticsLogger {
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

WalletEntity _wallet(int id, String name, WalletType type, int order) {
  final now = DateTime(2026, 10, 1);
  return WalletEntity(
    id: id,
    name: name,
    type: type,
    emoji: type.defaultEmoji,
    initialBalance: 0,
    currentBalance: 1000,
    accountNumber: null,
    note: null,
    sortOrder: order,
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );
}

/// Everything the add sheet reads, with the two mutation controllers mocked so a
/// test can assert on exactly what would be saved.
class AddEntryEnv {
  AddEntryEnv({
    required this.prefs,
    List<CategoryEntity>? categories,
    List<WalletEntity>? wallets,
  }) : categories = categories ?? defaultCategories,
       wallets =
           wallets ??
           [
             _wallet(1, 'নগদ টাকা', WalletType.cash, 0),
             _wallet(2, 'বিকাশ', WalletType.bkash, 1),
           ] {
    when(
      () => expenses.saveManualExpense(any(), walletId: any(named: 'walletId')),
    ).thenAnswer((_) async => null);
    when(
      () => incomes.saveManualIncome(any(), walletId: any(named: 'walletId')),
    ).thenAnswer((_) async => null);
  }

  final SharedPreferences prefs;
  final List<CategoryEntity> categories;
  final List<WalletEntity> wallets;
  final expenses = MockExpenseMutation();
  final incomes = MockIncomeMutation();
  final logger = _Logger();

  List<Override> get overrides => [
    sharedPreferencesProvider.overrideWithValue(prefs),
    categoryProvider.overrideWith(() => _FakeCategories(categories)),
    walletProvider.overrideWith(() => _FakeWallets(wallets)),
    expenseMutationControllerProvider.overrideWithValue(expenses),
    incomeMutationControllerProvider.overrideWithValue(incomes),
    usageAnalyticsProvider.overrideWithValue(UsageAnalytics(logger)),
  ];

  /// What the last saveManualExpense / saveManualIncome received.
  ExpenseEntity get savedExpense =>
      verify(
            () => expenses.saveManualExpense(
              captureAny(),
              walletId: any(named: 'walletId'),
            ),
          ).captured.single
          as ExpenseEntity;

  IncomeEntity get savedIncome =>
      verify(
            () => incomes.saveManualIncome(
              captureAny(),
              walletId: any(named: 'walletId'),
            ),
          ).captured.single
          as IncomeEntity;
}

Future<AddEntryEnv> newAddEntryEnv({
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  registerFallbackValue(
    ExpenseEntity(
      amount: 1,
      category: 'x',
      description: '',
      date: DateTime(2026),
    ),
  );
  registerFallbackValue(
    IncomeEntity(
      amount: 1,
      source: 'x',
      description: '',
      date: DateTime(2026),
      createdAt: DateTime(2026),
    ),
  );
  return AddEntryEnv(prefs: await SharedPreferences.getInstance());
}

/// A page with an "open" button that calls [showAddEntrySheet] — the real modal.
Widget addEntryApp(
  AddEntryEnv env, {
  EntryType initialType = EntryType.expense,
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
  bool throughManualAddWrapper = false,
}) {
  return ProviderScope(
    overrides: env.overrides,
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
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () =>
                  showAddEntrySheet(context, initialType: initialType),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}
