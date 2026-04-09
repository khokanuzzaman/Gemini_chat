import 'package:flutter/material.dart';

class ChatSuggestion {
  const ChatSuggestion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.draftText,
    required this.icon,
    required this.type,
    required this.priority,
  });

  final String id;
  final String title;
  final String subtitle;
  final String draftText;
  final IconData icon;
  final ChatSuggestionType type;
  final int priority;
}

class ChatSuggestionExpense {
  const ChatSuggestionExpense({
    required this.description,
    required this.category,
    required this.amount,
  });

  final String description;
  final String category;
  final int amount;
}

enum ChatSuggestionType { expense, income, split, smartMode, receipt, voice }

class ChatSuggestionEngine {
  const ChatSuggestionEngine();

  static const defaultLimit = 6;

  List<ChatSuggestion> build({
    required String input,
    required List<String> categoryNames,
    required List<ChatSuggestionExpense> recentExpenses,
    required bool ragEnabled,
    int limit = defaultLimit,
  }) {
    final query = _normalize(input);
    final hasQuery = query.isNotEmpty;
    final suggestions = <ChatSuggestion>[];

    suggestions.addAll(_baseSuggestions(query: query, ragEnabled: ragEnabled));
    suggestions.addAll(
      _categorySuggestions(query: query, categoryNames: categoryNames),
    );
    suggestions.addAll(
      _recentExpenseSuggestions(query: query, recentExpenses: recentExpenses),
    );

    final filtered = suggestions
        .where((suggestion) {
          if (!hasQuery) {
            return suggestion.priority >= 80;
          }

          return _matchesSuggestion(suggestion, query) ||
              _intentBoost(suggestion.type, query) > 0;
        })
        .toList(growable: false);

    final ranked = <_RankedSuggestion>[];
    for (final suggestion in filtered) {
      ranked.add(
        _RankedSuggestion(
          suggestion,
          suggestion.priority + _intentBoost(suggestion.type, query),
        ),
      );
    }

    ranked.sort((first, second) {
      final scoreCompare = second.score.compareTo(first.score);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return first.suggestion.title.compareTo(second.suggestion.title);
    });

    final deduped = <ChatSuggestion>[];
    final seenDrafts = <String>{};
    for (final rankedSuggestion in ranked) {
      final key = _normalize(rankedSuggestion.suggestion.draftText);
      if (seenDrafts.add(key)) {
        deduped.add(rankedSuggestion.suggestion);
      }
      if (deduped.length >= limit) {
        break;
      }
    }

    return deduped;
  }

  List<ChatSuggestion> _baseSuggestions({
    required String query,
    required bool ragEnabled,
  }) {
    final smartSubtitle = ragEnabled
        ? 'Smart Mode চালু আছে'
        : 'Smart Mode চালু করে ভালো insight পাবেন';

    return [
      const ChatSuggestion(
        id: 'starter-food',
        title: 'খাবার খরচ',
        subtitle: 'Expense draft',
        draftText: 'আজকে খাবারে ২২০ টাকা',
        icon: Icons.restaurant_rounded,
        type: ChatSuggestionType.expense,
        priority: 100,
      ),
      const ChatSuggestion(
        id: 'starter-transport',
        title: 'যাতায়াত খরচ',
        subtitle: 'Expense draft',
        draftText: 'গতকাল রিকশা ৮০ টাকা',
        icon: Icons.directions_car_rounded,
        type: ChatSuggestionType.expense,
        priority: 96,
      ),
      const ChatSuggestion(
        id: 'starter-income',
        title: 'আয় যোগ করুন',
        subtitle: 'Income draft',
        draftText: 'বেতন পেলাম ৩০,০০০ টাকা',
        icon: Icons.payments_rounded,
        type: ChatSuggestionType.income,
        priority: 94,
      ),
      const ChatSuggestion(
        id: 'starter-split',
        title: 'Split bill',
        subtitle: 'Group expense',
        draftText: 'Pizza ১২০০ টাকা ৪ জনে split',
        icon: Icons.group_work_rounded,
        type: ChatSuggestionType.split,
        priority: 92,
      ),
      ChatSuggestion(
        id: 'starter-month-smart',
        title: 'মাসিক insight',
        subtitle: smartSubtitle,
        draftText: 'এই মাসে কোথায় বেশি খরচ?',
        icon: Icons.psychology_rounded,
        type: ChatSuggestionType.smartMode,
        priority: 90,
      ),
      const ChatSuggestion(
        id: 'starter-receipt',
        title: 'রিসিট scan',
        subtitle: '+ button ব্যবহার করুন',
        draftText: 'রিসিট scan করতে + চাপুন',
        icon: Icons.receipt_long_rounded,
        type: ChatSuggestionType.receipt,
        priority: 88,
      ),
      const ChatSuggestion(
        id: 'expense-multiple',
        title: 'একাধিক খরচ',
        subtitle: 'Multiple expense draft',
        draftText: 'আজকে চা ৩০, দুপুরের খাবার ১৮০, রিকশা ৬০',
        icon: Icons.playlist_add_check_rounded,
        type: ChatSuggestionType.expense,
        priority: 76,
      ),
      const ChatSuggestion(
        id: 'income-freelance',
        title: 'Freelance income',
        subtitle: 'Income draft',
        draftText: 'আজকে freelance income ৫,০০০ টাকা',
        icon: Icons.work_outline_rounded,
        type: ChatSuggestionType.income,
        priority: 74,
      ),
      const ChatSuggestion(
        id: 'smart-today',
        title: 'আজকের summary',
        subtitle: 'Smart Mode question',
        draftText: 'আজকে কত খরচ হয়েছে?',
        icon: Icons.today_rounded,
        type: ChatSuggestionType.smartMode,
        priority: 72,
      ),
      const ChatSuggestion(
        id: 'smart-compare',
        title: 'মাস compare',
        subtitle: 'Smart Mode question',
        draftText: 'গত মাসের সাথে এই মাস compare করো',
        icon: Icons.stacked_line_chart_rounded,
        type: ChatSuggestionType.smartMode,
        priority: 70,
      ),
      const ChatSuggestion(
        id: 'voice-helper',
        title: 'ভয়েস input',
        subtitle: 'Mic button ব্যবহার করুন',
        draftText: 'ভয়েসে বলুন: আজকে খাবারে দুইশ বিশ টাকা',
        icon: Icons.mic_rounded,
        type: ChatSuggestionType.voice,
        priority: 68,
      ),
    ];
  }

  List<ChatSuggestion> _categorySuggestions({
    required String query,
    required List<String> categoryNames,
  }) {
    if (query.length < 2) {
      return const [];
    }

    final suggestions = <ChatSuggestion>[];
    for (final categoryName in categoryNames) {
      final normalizedCategory = _normalize(categoryName);
      if (!normalizedCategory.contains(query) &&
          !query.contains(normalizedCategory)) {
        continue;
      }

      suggestions.add(
        ChatSuggestion(
          id: 'category-$normalizedCategory',
          title: '$categoryName খরচ',
          subtitle: 'Category suggestion',
          draftText: 'আজকে $categoryName ২০০ টাকা',
          icon: Icons.category_rounded,
          type: ChatSuggestionType.expense,
          priority: 86,
        ),
      );
    }
    return suggestions;
  }

  List<ChatSuggestion> _recentExpenseSuggestions({
    required String query,
    required List<ChatSuggestionExpense> recentExpenses,
  }) {
    if (query.length < 2) {
      return const [];
    }

    final suggestions = <ChatSuggestion>[];
    for (final expense in recentExpenses) {
      final description = expense.description.trim();
      if (description.isEmpty) {
        continue;
      }

      final searchable = _normalize(
        '${expense.description} ${expense.category}',
      );
      if (!searchable.contains(query)) {
        continue;
      }

      suggestions.add(
        ChatSuggestion(
          id: 'recent-${_normalize(description)}-${expense.amount}',
          title: description,
          subtitle: 'সাম্প্রতিক ${expense.category}',
          draftText: 'আজকে $description ${expense.amount} টাকা',
          icon: Icons.history_rounded,
          type: ChatSuggestionType.expense,
          priority: 84,
        ),
      );
    }
    return suggestions;
  }

  bool _matchesSuggestion(ChatSuggestion suggestion, String query) {
    final searchable = _normalize(
      '${suggestion.title} ${suggestion.subtitle} ${suggestion.draftText}',
    );
    return searchable.contains(query);
  }

  int _intentBoost(ChatSuggestionType type, String query) {
    if (query.isEmpty) {
      return 0;
    }

    return switch (type) {
      ChatSuggestionType.expense =>
        _hasAny(query, const [
                  'খরচ',
                  'expense',
                  'আজ',
                  'আজকে',
                  'গতকাল',
                  'খা',
                  'food',
                  'transport',
                  'bill',
                  'টাকা',
                ]) ||
                _hasAmount(query)
            ? 35
            : 0,
      ChatSuggestionType.income =>
        _hasAny(query, const [
              'বেতন',
              'salary',
              'income',
              'bonus',
              'freelance',
              'আয়',
              'আয়',
              'পেলাম',
            ])
            ? 45
            : 0,
      ChatSuggestionType.split =>
        _hasAny(query, const ['split', 'ভাগ', 'জন', 'মিলে', 'মাথাপিছু'])
            ? 45
            : 0,
      ChatSuggestionType.smartMode =>
        _hasAny(query, const [
              'কত',
              'কোথায়',
              'কোথায়',
              'compare',
              'তুলনা',
              'এই মাস',
              'গত মাস',
              'summary',
              'breakdown',
            ])
            ? 45
            : 0,
      ChatSuggestionType.receipt =>
        _hasAny(query, const ['receipt', 'রিসিট', 'scan', 'স্ক্যান']) ? 45 : 0,
      ChatSuggestionType.voice =>
        _hasAny(query, const ['voice', 'ভয়েস', 'ভয়েস', 'mic', 'মাইক'])
            ? 45
            : 0,
    };
  }

  bool _hasAny(String input, List<String> keywords) {
    return keywords.any(input.contains);
  }

  bool _hasAmount(String input) {
    return RegExp(r'\d|[০-৯]').hasMatch(input);
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}

class _RankedSuggestion {
  const _RankedSuggestion(this.suggestion, this.score);

  final ChatSuggestion suggestion;
  final int score;
}
