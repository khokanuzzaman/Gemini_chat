import '../../features/category/domain/category_registry.dart';

enum RagResponseType {
  monthlySummary,
  categoryBreakdown,
  comparison,
  todaySummary,
  general,
}

class RecentTransaction {
  const RecentTransaction({
    required this.description,
    required this.category,
    required this.amount,
    required this.date,
  });

  final String description;
  final String category;
  final double amount;
  final String date;
}

class RagResponseData {
  const RagResponseData({
    required this.type,
    required this.aiText,
    required this.monthName,
    this.categoryData,
    this.totalAmount,
    this.lastMonthTotal,
    this.insights,
    this.recentItems,
    this.highlightedCategory,
    this.transactionCount,
    this.lastMonthCategoryData,
    this.lastMonthName,
  });

  final RagResponseType type;
  final String aiText;
  final Map<String, double>? categoryData;
  final double? totalAmount;
  final double? lastMonthTotal;
  final List<String>? insights;
  final List<RecentTransaction>? recentItems;
  final String monthName;
  final String? highlightedCategory;
  final int? transactionCount;
  final Map<String, double>? lastMonthCategoryData;
  final String? lastMonthName;

  RagResponseData copyWith({
    RagResponseType? type,
    String? aiText,
    Map<String, double>? categoryData,
    double? totalAmount,
    double? lastMonthTotal,
    List<String>? insights,
    List<RecentTransaction>? recentItems,
    String? monthName,
    String? highlightedCategory,
    int? transactionCount,
    Map<String, double>? lastMonthCategoryData,
    String? lastMonthName,
  }) {
    return RagResponseData(
      type: type ?? this.type,
      aiText: aiText ?? this.aiText,
      categoryData: categoryData ?? this.categoryData,
      totalAmount: totalAmount ?? this.totalAmount,
      lastMonthTotal: lastMonthTotal ?? this.lastMonthTotal,
      insights: insights ?? this.insights,
      recentItems: recentItems ?? this.recentItems,
      monthName: monthName ?? this.monthName,
      highlightedCategory: highlightedCategory ?? this.highlightedCategory,
      transactionCount: transactionCount ?? this.transactionCount,
      lastMonthCategoryData:
          lastMonthCategoryData ?? this.lastMonthCategoryData,
      lastMonthName: lastMonthName ?? this.lastMonthName,
    );
  }
}

class RagResponseParser {
  const RagResponseParser._();

  static RagResponseData parse(String aiResponse, String userQuestion) {
    final type = _detectType(userQuestion);
    final cleanText = aiResponse.trim();

    return RagResponseData(
      type: type,
      aiText: cleanText,
      insights: _extractInsights(cleanText),
      highlightedCategory: _detectHighlightedCategory(userQuestion),
      monthName: '',
    );
  }

  static RagResponseType _detectType(String userQuestion) {
    final question = userQuestion.toLowerCase();

    if (_containsAny(question, const ['আজকে', 'today'])) {
      return RagResponseType.todaySummary;
    }

    if (_containsAny(question, const ['তুলনা', 'compare', 'সাথে তুলনা'])) {
      return RagResponseType.comparison;
    }

    if (_detectHighlightedCategory(question) != null ||
        _containsAny(question, const [
          'category',
          'ক্যাটাগরি',
          'কোথায়',
          'কিসে',
          'সবচেয়ে',
        ])) {
      return RagResponseType.categoryBreakdown;
    }

    if (_containsAny(question, const [
      'মাস',
      'month',
      'total',
      'মোট',
      'গত মাস',
      'last month',
    ])) {
      return RagResponseType.monthlySummary;
    }

    return RagResponseType.general;
  }

  static String? _detectHighlightedCategory(String question) {
    final normalizedQuestion = question.toLowerCase();
    for (final category in CategoryRegistry.categories) {
      if (normalizedQuestion.contains(category.name.toLowerCase())) {
        return category.name;
      }
    }

    for (final entry in _categoryKeywords.entries) {
      if (entry.value.any(normalizedQuestion.contains)) {
        return entry.key;
      }
    }
    return null;
  }

  static bool _containsAny(String input, List<String> keywords) {
    return keywords.any(input.contains);
  }

  static List<String> _extractInsights(String aiResponse) {
    final paragraphs = aiResponse
        .split(RegExp(r'\n\s*\n'))
        .map((paragraph) => paragraph.trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .toList(growable: false);

    final bulletLines = aiResponse
        .split(RegExp(r'[\n\r]+'))
        .map((line) => line.trim())
        .where((line) => line.startsWith('-') || line.startsWith('•'))
        .map((line) => line.replaceFirst(RegExp(r'^[-•]\s*'), '').trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    if (bulletLines.isNotEmpty) {
      return bulletLines;
    }

    if (paragraphs.isEmpty) {
      return const [];
    }

    final lastParagraph = paragraphs.last;
    final sentences = lastParagraph
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (sentences.isNotEmpty) {
      return [sentences.last];
    }

    return [lastParagraph];
  }

  static const Map<String, List<String>> _categoryKeywords = {
    'Food': [
      'food',
      'খাবার',
      'নাস্তা',
      'লাঞ্চ',
      'ডিনার',
      'চা',
      'কফি',
      'রেস্তোরাঁ',
      'restaurant',
    ],
    'Transport': [
      'transport',
      'রিকশা',
      'বাস',
      'সিএনজি',
      'উবার',
      'পাঠাও',
      'ট্যাক্সি',
    ],
    'Healthcare': [
      'healthcare',
      'ডাক্তার',
      'ওষুধ',
      'হাসপাতাল',
      'ফার্মেসি',
      'ক্লিনিক',
    ],
    'Shopping': ['shopping', 'বাজার', 'সবজি', 'মাছ', 'মাংস', 'কাপড়', 'জুতা'],
    'Bill': [
      'bill',
      'বিদ্যুৎ',
      'গ্যাস',
      'পানি',
      'ইন্টারনেট',
      'ভাড়া',
      'রিচার্জ',
    ],
    'Entertainment': [
      'entertainment',
      'সিনেমা',
      'গেম',
      'ওটিটি',
      'কনসার্ট',
      'বই',
    ],
    'Other': ['other', 'অন্যান্য'],
  };
}
