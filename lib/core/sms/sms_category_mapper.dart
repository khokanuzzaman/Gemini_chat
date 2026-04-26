import '../../features/category/domain/category_registry.dart';
import '../../features/category/domain/entities/category_entity.dart';
import '../../features/income/domain/entities/income_source.dart';
import 'parsed_transaction.dart';

class SmsCategoryMapper {
  const SmsCategoryMapper();

  static const Map<String, List<String>> _expenseKeywordMap = {
    'Food': [
      'restaurant',
      'food',
      'cafe',
      'pizza',
      'burger',
      'chicken',
      'biryani',
      'কাবাব',
      'রেস্টুরেন্ট',
      'ফুডপান্ডা',
      'foodpanda',
      'hungry naki',
      'pathao food',
      'shohoz food',
    ],
    'Transport': [
      'uber',
      'pathao',
      'obhai',
      'shohoz',
      'railway',
      'বাস',
      'রিকশা',
      'fuel',
      'petrol',
      'cng',
    ],
    'Shopping': [
      'daraz',
      'evaly',
      'chaldal',
      'shwapno',
      'agora',
      'meena bazar',
      'aarong',
      'bata',
      'apex',
    ],
    'Healthcare': [
      'pharmacy',
      'hospital',
      'clinic',
      'lab',
      'ওষুধ',
      'ডাক্তার',
      'healthcare',
    ],
    'Bill': [
      'desco',
      'dpdc',
      'titas',
      'jalalabad gas',
      'dhaka wasa',
      'btcl',
      'গ্যাস',
      'বিদ্যুৎ',
      'পানি',
      'internet',
      'grameenphone',
      'robi',
      'banglalink',
      'airtel',
      'teletalk',
    ],
    'Entertainment': [
      'cinema',
      'star cineplex',
      'blockbuster',
      'netflix',
      'youtube premium',
      'spotify',
      'binge',
    ],
    'Education': [
      'school',
      'college',
      'university',
      'coaching',
      'tuition',
      'course',
      'udemy',
    ],
  };

  static const List<String> _salaryKeywords = [
    'salary',
    'payroll',
    'বেতন',
    'salary credit',
    'salary disbursement',
  ];
  static const List<String> _freelanceKeywords = [
    'fiverr',
    'upwork',
    'freelance',
    'project payment',
  ];
  static const List<String> _companyMarkers = [
    'ltd',
    'limited',
    'company',
    'co.',
    'corp',
    'inc',
    'technologies',
    'solutions',
    'software',
  ];

  String mapToExpenseCategory(ParsedTransaction transaction) {
    if (transaction.type != TransactionType.expense) {
      return _otherCategoryName();
    }

    final haystack = _buildHaystack(transaction);
    final customCategory = _matchCustomCategory(haystack);
    if (customCategory != null) {
      return customCategory;
    }

    for (final entry in _expenseKeywordMap.entries) {
      if (_containsAny(haystack, entry.value)) {
        return _resolveCategoryName(entry.key);
      }
    }

    return switch (transaction.kind) {
      ParsedTransactionKind.atmWithdrawal ||
      ParsedTransactionKind.cashOut ||
      ParsedTransactionKind.sendMoney ||
      ParsedTransactionKind.payment => _otherCategoryName(),
      _ => _otherCategoryName(),
    };
  }

  String mapToIncomeSource(ParsedTransaction transaction) {
    if (transaction.type != TransactionType.income) {
      return _resolveIncomeSourceName('Other');
    }

    final haystack = _buildHaystack(transaction);
    if (_containsAny(haystack, _freelanceKeywords)) {
      return _resolveIncomeSourceName('Freelance');
    }

    if (_containsAny(haystack, _salaryKeywords) ||
        _containsAny(haystack, _companyMarkers)) {
      return _resolveIncomeSourceName('Salary');
    }

    return switch (transaction.kind) {
      ParsedTransactionKind.receivedMoney ||
      ParsedTransactionKind.cashIn ||
      ParsedTransactionKind.bankCredit => _resolveIncomeSourceName('Other'),
      _ => _resolveIncomeSourceName('Other'),
    };
  }

  String _buildHaystack(ParsedTransaction transaction) {
    final pieces = [
      transaction.counterparty,
      transaction.merchantName,
      transaction.rawCategory,
      transaction.sender,
      transaction.rawMessage,
    ];
    return pieces
        .whereType<String>()
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .join(' ');
  }

  String? _matchCustomCategory(String haystack) {
    final customCategories = CategoryRegistry.categories.where(
      (category) => !category.isDefault,
    );
    for (final category in customCategories) {
      final candidate = category.name.trim().toLowerCase();
      if (candidate.isNotEmpty && haystack.contains(candidate)) {
        return category.name;
      }
    }
    return null;
  }

  String _resolveCategoryName(String requestedName) {
    final match = _findCategoryByName(requestedName);
    if (match != null) {
      return match.name;
    }
    return _otherCategoryName();
  }

  String _otherCategoryName() {
    return CategoryRegistry.otherCategory.name;
  }

  CategoryEntity? _findCategoryByName(String name) {
    return CategoryRegistry.findByName(name);
  }

  String _resolveIncomeSourceName(String requestedName) {
    return findIncomeSourceByName(requestedName)?.name ?? 'Other';
  }

  bool _containsAny(String haystack, List<String> keywords) {
    return keywords.any((keyword) => haystack.contains(keyword.toLowerCase()));
  }
}
