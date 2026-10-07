class UsageLimits {
  UsageLimits._();

  static const int aiChatPerDay = 20;
  static const int receiptScanPerDay = 5;
  static const int voiceInputPerDay = 10;
  static const int aiBudgetPerMonth = 3;

  static const String aiChat = 'ai_chat';
  static const String receiptScan = 'receipt_scan';
  static const String voiceInput = 'voice_input';
  static const String aiBudget = 'ai_budget';

  static const List<String> allFeatures = [
    aiChat,
    receiptScan,
    voiceInput,
    aiBudget,
  ];

  static int limitFor(String feature) {
    return switch (feature) {
      aiChat => aiChatPerDay,
      receiptScan => receiptScanPerDay,
      voiceInput => voiceInputPerDay,
      aiBudget => aiBudgetPerMonth,
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
      _ => feature,
    };
  }
}
