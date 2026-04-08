class IncomeSource {
  const IncomeSource({
    required this.name,
    required this.banglaLabel,
    required this.emoji,
    required this.sortOrder,
  });

  final String name;
  final String banglaLabel;
  final String emoji;
  final int sortOrder;
}

const defaultIncomeSources = <IncomeSource>[
  IncomeSource(
    name: 'Salary',
    banglaLabel: 'বেতন',
    emoji: '💼',
    sortOrder: 1,
  ),
  IncomeSource(
    name: 'Freelance',
    banglaLabel: 'ফ্রিল্যান্স',
    emoji: '💻',
    sortOrder: 2,
  ),
  IncomeSource(
    name: 'Business',
    banglaLabel: 'ব্যবসা',
    emoji: '🏪',
    sortOrder: 3,
  ),
  IncomeSource(
    name: 'Investment',
    banglaLabel: 'বিনিয়োগ',
    emoji: '📈',
    sortOrder: 4,
  ),
  IncomeSource(
    name: 'Gift',
    banglaLabel: 'উপহার',
    emoji: '🎁',
    sortOrder: 5,
  ),
  IncomeSource(
    name: 'Bonus',
    banglaLabel: 'বোনাস',
    emoji: '🎉',
    sortOrder: 6,
  ),
  IncomeSource(
    name: 'Rental',
    banglaLabel: 'ভাড়া',
    emoji: '🏠',
    sortOrder: 7,
  ),
  IncomeSource(
    name: 'Other',
    banglaLabel: 'অন্যান্য',
    emoji: '💰',
    sortOrder: 8,
  ),
];

IncomeSource? findIncomeSourceByName(String name) {
  final normalized = name.trim().toLowerCase();
  for (final source in defaultIncomeSources) {
    if (source.name.toLowerCase() == normalized) {
      return source;
    }
  }
  return null;
}
