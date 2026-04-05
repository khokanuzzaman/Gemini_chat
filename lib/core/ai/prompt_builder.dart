import '../../features/category/domain/entities/category_entity.dart';

class PromptBuilder {
  const PromptBuilder._();

  static String buildChatSystemPrompt(List<CategoryEntity> categories) {
    final availableCategories = categories.isEmpty
        ? defaultCategories
        : categories;
    final categoryNames = availableCategories
        .map((category) => category.name)
        .join(', ');
    final categoryHints = availableCategories
        .map(
          (category) => '- ${category.name}: ${_categoryHint(category.name)}',
        )
        .join('\n');

    return '''
You are a personal finance assistant for Bangladesh.
Always respond in Bengali. Be concise and helpful.

## EXPENSE DETECTION
When user mentions any expense, return JSON array before your response.
Always use array format, even for single expense.

## CATEGORY RULES
Use only one category from this list:
$categoryNames

Prefer a custom category when it matches the expense better than a generic one.
If a user-created category fits naturally, use it.

## CATEGORY HINTS
$categoryHints

## FEW-SHOT EXAMPLES
User: "নাস্তায় ৩০ টাকা খরচ হলো"
[{"amount":30,"category":"Food","description":"নাস্তা","date":"today"}]

User: "রিকশায় গেলাম ৬০ টাকা, দুপুরে খেলাম ১৫০"
[{"amount":60,"category":"Transport","description":"রিকশা","date":"today"},{"amount":150,"category":"Food","description":"দুপুরের খাবার","date":"today"}]

User: "আমরা ৪ জন মিলে ৮০০ টাকার খাবার খেলাম"
[{"amount":800,"category":"Food","description":"দলের খাবার","date":"today","isSplit":true,"splitPersons":4}]

User: "হ্যালো কেমন আছ"
(no JSON — normal chat)

## DATE EXTRACTION RULES
Always extract the actual date mentioned by user.
Convert to ISO format: YYYY-MM-DD

Recognize:
- DD/MM/YYYY
- DD-MM-YYYY
- Bengali dates
- Relative dates like গতকাল, পরশু
- Named weekdays like গত সোমবার
- If no date is mentioned, use "today"

When a date appears at the top of the message, apply that date to all items below it.

## RULES
- Skip "মোট" or "total" lines
- Amount must be a positive number
- If amount is unclear, skip that item
- Always use ISO date in JSON, never relative words
- When the user is describing a group bill with words like "আমরা", "জন মিলে", "ভাগ", "split", or "মাথাপিছু", add "isSplit": true
- If person count is mentioned for a group bill, add "splitPersons": <number>, otherwise use null
- Current year is 2026 if year is missing
- After JSON, continue naturally in Bengali

## ADDITIONAL CONTEXT AWARENESS
If user asks about:
- "goal" or "লক্ষ্য" -> refer to goal data in context
- "budget" or "বাজেট" -> refer to budget plan in context
- "recurring" or "নিয়মিত" -> refer to recurring data
- "split" or "ভাগ" -> help with split calculation
- "unusual" or "অস্বাভাবিক" -> refer to anomaly data
''';
  }

  static String buildReceiptSystemPrompt(List<CategoryEntity> categories) {
    final availableCategories = categories.isEmpty
        ? defaultCategories
        : categories;
    final categoryNames = availableCategories
        .map((category) => category.name)
        .join(', ');

    return '''
You are a receipt parser.
Analyze the OCR-extracted receipt text and return ONLY this JSON:
{
  "merchant": "<shop name>",
  "total": <number>,
  "date": "<date or today>",
  "items": [
    {"name": "<item>", "amount": <price>}
  ],
  "category": "<one of: $categoryNames>",
  "summary": "<one line Bengali summary>"
}
Use the most suitable category from: $categoryNames
If text is not a receipt, return: {"error": "not_a_receipt"}
Return JSON only, no extra text.
''';
  }

  static String _categoryHint(String categoryName) {
    final normalized = categoryName.toLowerCase();
    if (normalized == 'food') {
      return 'খাবার, নাস্তা, চা, কফি, রেস্তোরাঁ';
    }
    if (normalized == 'transport') {
      return 'রিকশা, বাস, উবার, ট্রেন, ভাড়া';
    }
    if (normalized == 'healthcare') {
      return 'ডাক্তার, ওষুধ, হাসপাতাল, টেস্ট';
    }
    if (normalized == 'shopping') {
      return 'বাজার, কাপড়, জুতা, মুদিখানা, কেনাকাটা';
    }
    if (normalized == 'bill') {
      return 'বিদ্যুৎ, পানি, গ্যাস, ইন্টারনেট, ভাড়া';
    }
    if (normalized == 'entertainment') {
      return 'সিনেমা, গেম, কনসার্ট, ওটিটি';
    }
    if (normalized == 'other') {
      return 'অন্য কোনো খরচ';
    }
    if (normalized.contains('education') || normalized.contains('study')) {
      return 'বই, কোচিং, টিউশন, স্কুল, কলেজ, কোর্স';
    }
    if (normalized.contains('gym') || normalized.contains('fitness')) {
      return 'জিম, workout, training, fitness';
    }
    if (normalized.contains('pet')) {
      return 'pet food, vet, প্রাণীর যত্ন';
    }
    if (normalized.contains('travel')) {
      return 'trip, hotel, tour, travel cost';
    }
    if (normalized.contains('home')) {
      return 'বাসা, furniture, household items';
    }
    return '$categoryName related expenses';
  }
}
