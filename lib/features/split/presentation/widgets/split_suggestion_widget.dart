// Feature: Split
// Layer: Presentation

import 'package:flutter/material.dart';

import '../../../../core/ai/expense_result.dart';
import '../../../../core/utils/bangla_formatters.dart';

class SplitSuggestionWidget extends StatelessWidget {
  const SplitSuggestionWidget({
    super.key,
    required this.expense,
    required this.personCount,
    required this.onSaveOnly,
    required this.onOpenSplit,
  });

  final ExpenseData expense;
  final int personCount;
  final Future<void> Function() onSaveOnly;
  final VoidCallback onOpenSplit;

  @override
  Widget build(BuildContext context) {
    final normalizedCount = personCount < 2 ? 2 : personCount;
    final perPerson = normalizedCount == 0
        ? 0.0
        : expense.amount / normalizedCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bill split করবেন?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'মোট: ${BanglaFormatters.preciseCurrency(expense.amount)} · ${BanglaFormatters.count(normalizedCount)} জন = ${BanglaFormatters.preciseCurrency(perPerson)} জনপ্রতি',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSaveOnly,
                    child: const Text('শুধু save করুন'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onOpenSplit,
                    icon: const Icon(Icons.call_split_rounded, size: 16),
                    label: const Text('Split করুন'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
