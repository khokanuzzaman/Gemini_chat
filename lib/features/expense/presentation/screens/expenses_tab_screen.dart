import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../income/presentation/screens/income_list_screen.dart';
import 'expense_list_screen.dart';

/// খরচ tab — hosts the expense and income lists under one scaffold with a
/// খরচ | আয় segment (§4). A single app bar; the FAB and filter delegate to the
/// active segment's body via its GlobalKey, so there is no second app bar.
class ExpensesTabScreen extends StatefulWidget {
  const ExpensesTabScreen({super.key});

  @override
  State<ExpensesTabScreen> createState() => _ExpensesTabScreenState();
}

class _ExpensesTabScreenState extends State<ExpensesTabScreen> {
  bool _isIncome = false;

  final _expenseKey = GlobalKey<ExpenseListBodyState>();
  final _incomeKey = GlobalKey<IncomeListBodyState>();

  void _openFilter() {
    if (_isIncome) {
      _incomeKey.currentState?.openFilter();
    } else {
      _expenseKey.currentState?.openFilter();
    }
  }

  void _openAdd() {
    if (_isIncome) {
      _incomeKey.currentState?.openAdd();
    } else {
      _expenseKey.currentState?.openAdd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      showBackButton: false,
      showOfflineBanner: false,
      titleWidget: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, label: Text('খরচ')),
          ButtonSegment(value: true, label: Text('আয়')),
        ],
        selected: {_isIncome},
        showSelectedIcon: false,
        onSelectionChanged: (selection) =>
            setState(() => _isIncome = selection.first),
      ),
      actions: [
        IconButton(
          onPressed: _openFilter,
          icon: const Icon(Icons.filter_alt_outlined),
          tooltip: 'ফিল্টার',
        ),
        const GlobalSettingsButton(),
      ],
      floatingActionButton: FloatingActionButton(
        backgroundColor: _isIncome ? AppColors.success : null,
        onPressed: _openAdd,
        child: const Icon(Icons.add_rounded),
      ),
      body: IndexedStack(
        index: _isIncome ? 1 : 0,
        children: [
          ExpenseListBody(key: _expenseKey),
          IncomeListBody(key: _incomeKey),
        ],
      ),
    );
  }
}
