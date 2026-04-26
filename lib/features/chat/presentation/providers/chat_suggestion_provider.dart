import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../expense/presentation/providers/expense_providers.dart';
import '../utils/chat_suggestion_engine.dart';

final chatSuggestionHistoryProvider =
    FutureProvider<List<ChatSuggestionExpense>>((ref) async {
      ref.watch(expenseRefreshTokenProvider);

      final expenses = await ref
          .watch(expenseRepositoryProvider)
          .getAllExpenses();
      final suggestions = <ChatSuggestionExpense>[];
      final seen = <String>{};

      for (final expense in expenses.take(30)) {
        final description = expense.description.trim();
        if (description.isEmpty) {
          continue;
        }

        final key = '${description.toLowerCase()}|${expense.category}';
        if (!seen.add(key)) {
          continue;
        }

        suggestions.add(
          ChatSuggestionExpense(
            description: description,
            category: expense.category,
            amount: expense.amount.round(),
          ),
        );

        if (suggestions.length >= 12) {
          break;
        }
      }

      return suggestions;
    });
