class UsageLimits {
  UsageLimits._();

  static const int aiChatPerDay = 20;
  static const int receiptScanPerDay = 5;
  static const int voiceInputPerDay = 10;
  static const int aiBudgetPerMonth = 3;
  static const int cloudBackupPerDay = 1;

  static const String aiChat = 'ai_chat';
  static const String receiptScan = 'receipt_scan';
  static const String voiceInput = 'voice_input';
  static const String aiBudget = 'ai_budget';
  static const String cloudBackup = 'cloud_backup';

  static const List<String> allFeatures = [
    aiChat,
    receiptScan,
    voiceInput,
    aiBudget,
    cloudBackup,
  ];

  static int limitFor(String feature) {
    return switch (feature) {
      aiChat => aiChatPerDay,
      receiptScan => receiptScanPerDay,
      voiceInput => voiceInputPerDay,
      aiBudget => aiBudgetPerMonth,
      cloudBackup => cloudBackupPerDay,
      _ => 0,
    };
  }

  static bool isMonthly(String feature) => feature == aiBudget;

  static String bengaliName(String feature) {
    return switch (feature) {
      aiChat => 'AI চ্যাট',
      receiptScan => 'রিসিট স্ক্যান',
      voiceInput => 'ভয়েস ইনপুট',
      aiBudget => 'AI বাজেট',
      cloudBackup => 'ক্লাউড ব্যাকআপ',
      _ => feature,
    };
  }
}
