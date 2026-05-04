import 'package:flutter/material.dart';

import '../../../../../core/utils/bangla_formatters.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../domain/entities/expense_entity.dart';
import '../../utils/expense_category_meta.dart';

class RecentTransactionTile extends StatelessWidget {
  const RecentTransactionTile({super.key, required this.expense});

  final ExpenseEntity expense;

  @override
  Widget build(BuildContext context) {
    final meta = resolveExpenseCategory(expense.category);
    return AppListTile(
      title: expense.description,
      subtitle:
          '${BanglaFormatters.relativeDay(expense.date)} · ${expense.category}',
      leadingIcon: meta.icon,
      leadingColor: meta.color,
      trailingAmount: expense.amount,
      trailingAmountIsExpense: true,
      dense: true,
    );
  }
}
