import 'dart:convert';

import '../../features/category/domain/category_registry.dart';
import 'expense_result.dart';

class ExpenseParser {
  const ExpenseParser();

  static final _jsonFenceRegex = RegExp(
    r'```(?:json)?\s*([\s\S]*?)```',
    caseSensitive: false,
  );
  static final _arrayRegex = RegExp(r'\[[\s\S]*?\]');

  /// Parses an AI response and extracts expense data plus conversational text.
  ExpenseResult parseExpenseFromResponse(String response) {
    final trimmedResponse = response.trim();
    if (trimmedResponse.isEmpty) {
      return const ExpenseResult(isExpense: false);
    }

    final receiptResult = _tryParseReceipt(trimmedResponse);
    if (receiptResult != null) {
      return receiptResult;
    }

    final arrayMatch = _arrayRegex.firstMatch(trimmedResponse);
    if (arrayMatch != null) {
      final parsedArrayResult = _parseExpenseArray(
        arrayMatch.group(0)!,
        trimmedResponse,
      );
      if (parsedArrayResult != null) {
        return parsedArrayResult;
      }
    }

    for (final jsonString in _extractJsonCandidates(trimmedResponse)) {
      final fallbackSingleResult = _parseSingleExpenseObject(
        jsonString,
        trimmedResponse,
      );
      if (fallbackSingleResult != null) {
        return fallbackSingleResult;
      }
    }

    return ExpenseResult(isExpense: false, conversationalText: trimmedResponse);
  }

  ExpenseResult? _tryParseReceipt(String response) {
    for (final jsonString in _extractJsonCandidates(response)) {
      try {
        final decoded = jsonDecode(jsonString);
        if (decoded is! Map) {
          continue;
        }

        final receiptData = Map<String, dynamic>.from(decoded);
        if (!_looksLikeReceipt(receiptData)) {
          continue;
        }

        final parsedReceipt = _parseReceiptJson(receiptData, response);
        if (parsedReceipt == null) {
          continue;
        }

        final cleanText = response.replaceFirst(jsonString, '').trim();
        final receiptExpenses = _receiptItemsToExpenses(parsedReceipt);
        final summary = parsedReceipt['summary'] as String?;
        final conversationalText = cleanText.isNotEmpty
            ? cleanText
            : (summary != null && summary.trim().isNotEmpty
                  ? summary.trim()
                  : null);

        return ExpenseResult(
          isExpense: true,
          isReceipt: true,
          expenses: receiptExpenses,
          isMultiple: receiptExpenses.length > 1,
          conversationalText: conversationalText,
          receiptData: parsedReceipt,
        );
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  ExpenseResult? _parseExpenseArray(String jsonString, String response) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! List) {
        return null;
      }

      final expenses = decoded
          .whereType<Map>()
          .map((item) => ExpenseData.fromJson(Map<String, dynamic>.from(item)))
          .map(_normalizeExpenseCategory)
          .where((expense) => expense.isValid)
          .where((expense) => _supportedCategories.contains(expense.category))
          .toList(growable: false);

      if (expenses.isEmpty) {
        return null;
      }

      final cleanText = response.replaceFirst(jsonString, '').trim();
      return ExpenseResult(
        isExpense: true,
        expenses: expenses,
        isMultiple: expenses.length > 1,
        conversationalText: cleanText.isEmpty ? null : cleanText,
      );
    } catch (_) {
      return null;
    }
  }

  ExpenseResult? _parseSingleExpenseObject(String jsonString, String response) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map) {
        return null;
      }

      final expense = _normalizeExpenseCategory(
        ExpenseData.fromJson(Map<String, dynamic>.from(decoded)),
      );
      if (!expense.isValid ||
          !_supportedCategories.contains(expense.category)) {
        return null;
      }

      final cleanText = response.replaceFirst(jsonString, '').trim();
      return ExpenseResult(
        isExpense: true,
        expenses: [expense],
        conversationalText: cleanText.isEmpty ? null : cleanText,
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _parseReceiptJson(
    Map<String, dynamic> receiptData,
    String fallbackText,
  ) {
    final merchant = receiptData['merchant'];
    final totalValue = receiptData['total'];
    final dateValue = receiptData['date'];
    final itemsValue = receiptData['items'];
    final categoryValue = receiptData['category'];
    final summaryValue = receiptData['summary'];

    final normalizedTotal = switch (totalValue) {
      num value => value,
      String value => num.tryParse(value),
      _ => null,
    };

    if (merchant is! String ||
        merchant.trim().isEmpty ||
        normalizedTotal == null ||
        dateValue is! String ||
        dateValue.trim().isEmpty ||
        categoryValue is! String ||
        itemsValue is! List ||
        itemsValue.isEmpty) {
      return null;
    }

    final normalizedCategory = _normalizedCategory(categoryValue);
    if (normalizedCategory == null) {
      return null;
    }

    final normalizedItems = <Map<String, dynamic>>[];
    for (final item in itemsValue) {
      if (item is! Map) {
        return null;
      }

      final itemMap = Map<String, dynamic>.from(item);
      final nameValue = itemMap['name'];
      final amountValue = itemMap['amount'];
      final normalizedAmount = switch (amountValue) {
        num value => value,
        String value => num.tryParse(value),
        _ => null,
      };

      if (nameValue is! String ||
          nameValue.trim().isEmpty ||
          normalizedAmount == null) {
        return null;
      }

      normalizedItems.add({
        'name': nameValue.trim(),
        'amount': normalizedAmount,
      });
    }

    return {
      'merchant': merchant.trim(),
      'total': normalizedTotal,
      'date': dateValue.trim(),
      'items': normalizedItems,
      'category': normalizedCategory,
      'summary': summaryValue is String ? summaryValue.trim() : fallbackText,
    };
  }

  bool _looksLikeReceipt(Map<String, dynamic> data) {
    return data.containsKey('merchant') &&
        data.containsKey('items') &&
        data.containsKey('total');
  }

  List<ExpenseData> _receiptItemsToExpenses(Map<String, dynamic> receiptData) {
    final category =
        _normalizedCategory(receiptData['category'] as String?) ?? 'Other';
    final date = receiptData['date'] as String? ?? 'today';
    final items = (receiptData['items'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(
          (item) => ExpenseData(
            amount: switch (item['amount']) {
              num value => value.toDouble(),
              String value => double.tryParse(value) ?? 0,
              _ => 0,
            },
            category: category,
            description: item['name'] as String? ?? '',
            date: date,
          ),
        )
        .where((expense) => expense.isValid)
        .toList(growable: false);

    return items;
  }

  List<String> _extractJsonCandidates(String response) {
    final candidates = <String>[];
    final unique = <String>{};

    for (final match in _jsonFenceRegex.allMatches(response)) {
      final candidate = match.group(1)?.trim();
      if (candidate != null && unique.add(candidate)) {
        candidates.add(candidate);
      }
    }

    for (final candidate in _extractBalancedJsonObjects(response)) {
      if (unique.add(candidate)) {
        candidates.add(candidate);
      }
    }

    return candidates;
  }

  List<String> _extractBalancedJsonObjects(String text) {
    final objects = <String>[];
    var depth = 0;
    var startIndex = -1;
    var inString = false;
    var isEscaping = false;

    for (var index = 0; index < text.length; index++) {
      final char = text[index];

      if (isEscaping) {
        isEscaping = false;
        continue;
      }

      if (char == '\\' && inString) {
        isEscaping = true;
        continue;
      }

      if (char == '"') {
        inString = !inString;
        continue;
      }

      if (inString) {
        continue;
      }

      if (char == '{') {
        if (depth == 0) {
          startIndex = index;
        }
        depth += 1;
      } else if (char == '}' && depth > 0) {
        depth -= 1;
        if (depth == 0 && startIndex >= 0) {
          objects.add(text.substring(startIndex, index + 1).trim());
          startIndex = -1;
        }
      }
    }

    return objects;
  }

  ExpenseData _normalizeExpenseCategory(ExpenseData expense) {
    final normalizedCategory = _normalizedCategory(expense.category);
    if (normalizedCategory == null) {
      return expense;
    }

    return expense.copyWith(category: normalizedCategory);
  }

  Set<String> get _supportedCategories =>
      CategoryRegistry.categoryNames.toSet();

  String? _normalizedCategory(String? rawCategory) {
    if (rawCategory == null) {
      return null;
    }

    final normalized = rawCategory.trim().toLowerCase();
    for (final category in CategoryRegistry.categories) {
      if (category.name.trim().toLowerCase() == normalized) {
        return category.name;
      }
    }
    return null;
  }
}
