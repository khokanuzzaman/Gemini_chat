import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/core/ai/expense_parser.dart';
import 'package:gemini_chat/features/category/domain/category_registry.dart';
import 'package:gemini_chat/features/category/domain/entities/category_entity.dart';

void main() {
  final parser = ExpenseParser();

  tearDown(() {
    CategoryRegistry.setCategories(defaultCategories);
  });

  test('parser accepts a custom category from the registry', () {
    CategoryRegistry.setCategories([
      ...defaultCategories,
      CategoryEntity(
        id: 99,
        name: 'Education',
        icon: 'school',
        colorValue: 0xFF1A73E8,
        isDefault: false,
        sortOrder: 8,
        createdAt: DateTime(2026, 4, 5),
      ),
    ]);

    const response =
        '[{"amount":300,"category":"Education","description":"বই","date":"today"}]\nSave করব?';
    final result = parser.parseExpenseFromResponse(response);

    expect(result.isExpense, isTrue);
    expect(result.expenses, hasLength(1));
    expect(result.expenses.first.category, 'Education');
    expect(result.expenses.first.description, 'বই');
  });

  test('receipt parser accepts a custom category from the registry', () {
    CategoryRegistry.setCategories([
      ...defaultCategories,
      CategoryEntity(
        id: 100,
        name: 'Pet',
        icon: 'pets',
        colorValue: 0xFF8D6E63,
        isDefault: false,
        sortOrder: 8,
        createdAt: DateTime(2026, 4, 5),
      ),
    ]);

    const response =
        '{"merchant":"Pet Store","total":850,"date":"2026-04-05","items":[{"name":"Cat food","amount":850}],"category":"Pet","summary":"Pet food কিনেছেন"}';
    final result = parser.parseExpenseFromResponse(response);

    expect(result.isExpense, isTrue);
    expect(result.isReceipt, isTrue);
    expect(result.expenses, hasLength(1));
    expect(result.expenses.first.category, 'Pet');
  });
}
