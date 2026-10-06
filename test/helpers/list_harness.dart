import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gemini_chat/core/theme/app_theme.dart';
import 'package:gemini_chat/features/category/domain/entities/category_entity.dart';
import 'package:gemini_chat/features/category/presentation/providers/category_provider.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_entity.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_list_filter.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_source.dart';
import 'package:gemini_chat/features/expense/presentation/providers/expense_providers.dart';
import 'package:gemini_chat/features/income/domain/entities/income_entity.dart';
import 'package:gemini_chat/features/recurring/domain/entities/recurring_expense_entity.dart';
import 'package:gemini_chat/features/recurring/presentation/providers/recurring_provider.dart';
import 'package:gemini_chat/features/income/presentation/providers/income_providers.dart';
import 'package:gemini_chat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:gemini_chat/features/wallet/presentation/providers/wallet_provider.dart';

/// Records what the list asked the controller to do, so a test can assert on the
/// delete call without a database.
class ListCalls {
  final deletedExpenses = <ExpenseEntity>[];
  final deletedIncomes = <IncomeEntity>[];
  final updatedExpenses = <ExpenseEntity>[];
  final markedRecurring = <ExpenseEntity>[];
  String? updateError;
  int clearFilters = 0;
}

class FakeExpenseList extends ExpenseListController {
  FakeExpenseList(
    this.items,
    this.calls, {
    this.filter = const ExpenseListFilter(),
  });
  final List<ExpenseEntity> items;
  final ListCalls calls;
  final ExpenseListFilter filter;

  @override
  Future<ExpenseListState> build() async =>
      ExpenseListState(expenses: items, filter: filter);

  @override
  Future<String?> deleteExpense(ExpenseEntity expense) async {
    calls.deletedExpenses.add(expense);
    return null;
  }

  @override
  Future<void> clearFilters() async {
    calls.clearFilters++;
  }

  @override
  Future<String?> updateExpense(ExpenseEntity input) async {
    calls.updatedExpenses.add(input);
    return calls.updateError;
  }
}

class FakeRecurring extends RecurringNotifier {
  FakeRecurring(this.calls);
  final ListCalls calls;

  @override
  Future<List<RecurringExpenseEntity>> build() async => const [];

  @override
  Future<MarkRecurringResult> markExpenseAsRecurring(
    ExpenseEntity expense,
  ) async {
    calls.markedRecurring.add(expense);
    return MarkRecurringResult.added;
  }
}

class FakeIncomeList extends IncomeListController {
  FakeIncomeList(this.items, this.calls);
  final List<IncomeEntity> items;
  final ListCalls calls;

  @override
  Future<List<IncomeEntity>> build() async => items;

  @override
  Future<String?> deleteIncome(IncomeEntity income) async {
    calls.deletedIncomes.add(income);
    return null;
  }
}

class _FakeWallets extends WalletNotifier {
  _FakeWallets(this.items);
  final List<WalletEntity> items;
  @override
  Future<List<WalletEntity>> build() async => items;
}

class _FakeCategories extends CategoryNotifier {
  @override
  List<CategoryEntity> build() => defaultCategories;
}

WalletEntity listWallet(int id, String name, String emoji) => WalletEntity(
  id: id,
  name: name,
  type: WalletType.cash,
  emoji: emoji,
  initialBalance: 0,
  currentBalance: 1000,
  accountNumber: null,
  note: null,
  sortOrder: id,
  isArchived: false,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

final listWallets = [
  listWallet(1, 'নগদ টাকা', '💵'),
  listWallet(2, 'বিকাশ', '📱'),
];

ExpenseEntity listExpense({
  required int id,
  required DateTime date,
  double amount = 100,
  String category = 'Food',
  String description = 'দুপুরের খাবার',
  int walletId = 1,
  ExpenseSource source = ExpenseSource.expense,
}) => ExpenseEntity(
  id: id,
  amount: amount,
  category: category,
  description: description,
  date: date,
  walletId: walletId,
  sourceType: source,
  sourceId: source == ExpenseSource.expense ? null : 7,
);

IncomeEntity listIncome({
  required int id,
  required DateTime date,
  double amount = 5000,
  String source = 'Salary',
  String description = '',
  int walletId = 1,
}) => IncomeEntity(
  id: id,
  amount: amount,
  source: source,
  description: description,
  date: date,
  walletId: walletId,
  createdAt: date,
);

List<Override> listOverrides({
  List<ExpenseEntity> expenses = const [],
  List<IncomeEntity> incomes = const [],
  required ListCalls calls,
  ExpenseListFilter filter = const ExpenseListFilter(),
  IncomeMutationController? incomeMutation,
}) => [
  if (incomeMutation != null)
    incomeMutationControllerProvider.overrideWithValue(incomeMutation),
  recurringProvider.overrideWith(() => FakeRecurring(calls)),
  expenseListControllerProvider.overrideWith(
    () => FakeExpenseList(expenses, calls, filter: filter),
  ),
  incomeListControllerProvider.overrideWith(
    () => FakeIncomeList(incomes, calls),
  ),
  walletProvider.overrideWith(() => _FakeWallets(listWallets)),
  categoryProvider.overrideWith(_FakeCategories.new),
];

/// Hosts [child] (a list body) like the খরচ tab does: scaffold + bounded body.
Widget listApp({
  required Widget child,
  required List<Override> overrides,
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
  bool scaffold = true,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.dark
          ? AppTheme.darkTheme()
          : AppTheme.lightTheme(),
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: c!,
      ),
      home: scaffold ? Scaffold(body: child) : child,
    ),
  );
}
