import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/core/ai/prompt_builder.dart';
import 'package:gemini_chat/features/category/domain/entities/category_entity.dart';

void main() {
  test('chat prompt includes custom categories', () {
    final prompt = PromptBuilder.buildChatSystemPrompt([
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

    expect(prompt, contains('Use only one category from this list'));
    expect(prompt, contains('Education'));
    expect(prompt, contains('বই, কোচিং, টিউশন'));
  });

  test('receipt prompt includes custom categories', () {
    final prompt = PromptBuilder.buildReceiptSystemPrompt([
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

    expect(prompt, contains('Pet'));
    expect(prompt, contains('"category": "<one of:'));
  });
}
