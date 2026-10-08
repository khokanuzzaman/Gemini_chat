class WalletEntity {
  const WalletEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.emoji,
    required this.initialBalance,
    required this.currentBalance,
    required this.accountNumber,
    required this.note,
    required this.sortOrder,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final WalletType type;
  final String emoji;
  final double initialBalance;
  final double currentBalance;
  final String? accountNumber;
  final String? note;
  final int sortOrder;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The name to SHOW. The two seeded defaults are stored in English ("Cash",
  /// "Bank Account") and the stored value must not change (SMS wallet matching,
  /// backups and snapshots key on it), so they are translated here, display only.
  /// Any other name — including one the user typed — is returned as is.
  String get shownName => switch ((type, name)) {
    (WalletType.cash, 'Cash') => 'নগদ টাকা',
    (WalletType.bank, 'Bank Account') => 'ব্যাংক অ্যাকাউন্ট',
    _ => name,
  };

  String get displayName => '$emoji $shownName';

  WalletEntity copyWith({
    int? id,
    String? name,
    WalletType? type,
    String? emoji,
    double? initialBalance,
    double? currentBalance,
    String? accountNumber,
    bool clearAccountNumber = false,
    String? note,
    bool clearNote = false,
    int? sortOrder,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      emoji: emoji ?? this.emoji,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      accountNumber: clearAccountNumber
          ? null
          : accountNumber ?? this.accountNumber,
      note: clearNote ? null : note ?? this.note,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum WalletType { cash, bkash, nagad, rocket, bank, card, other }

extension WalletTypeX on WalletType {
  String get labelBn => switch (this) {
    WalletType.cash => 'ক্যাশ',
    WalletType.bkash => 'বিকাশ',
    WalletType.nagad => 'নগদ',
    WalletType.rocket => 'রকেট',
    WalletType.bank => 'ব্যাংক',
    WalletType.card => 'কার্ড',
    WalletType.other => 'অন্যান্য',
  };

  String get categoryLabelBn => switch (this) {
    WalletType.cash => 'নগদ',
    WalletType.bkash => 'মোবাইল ব্যাংকিং',
    WalletType.nagad => 'মোবাইল ব্যাংকিং',
    WalletType.rocket => 'মোবাইল ব্যাংকিং',
    WalletType.bank => 'ব্যাংক একাউন্ট',
    WalletType.card => 'কার্ড',
    WalletType.other => 'অন্যান্য',
  };

  String get defaultEmoji => switch (this) {
    WalletType.cash => '💵',
    WalletType.bkash => '📱',
    WalletType.nagad => '📲',
    WalletType.rocket => '🚀',
    WalletType.bank => '🏦',
    WalletType.card => '💳',
    WalletType.other => '👛',
  };
}
