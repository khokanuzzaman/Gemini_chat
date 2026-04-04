// Feature: Core
// Layer: Constants

/// Shared user-facing copy used across the app.
class AppStrings {
  const AppStrings._();

  static const noInternet = 'ইন্টারনেট সংযোগ নেই';
  static const apiKeyInvalid = 'API key সঠিক নয়';
  static const apiKeyInvalidWithEnv = 'API key সঠিক নয়। .env চেক করুন।';
  static const quotaExceeded = 'Limit শেষ, পরে চেষ্টা করুন';
  static const timeout = 'সময় শেষ, আবার চেষ্টা করুন';
  static const generalError = 'কিছু একটা সমস্যা হয়েছে';
  static const storageError = 'লোকাল data অ্যাক্সেস করা যায়নি';
  static const micPermission = 'Microphone permission দিন';
  static const micPermissionSettings =
      'Microphone permission দিন settings থেকে';
  static const cameraPermission = 'Camera permission দিন';
  static const cameraPermissionSettings = 'Camera permission দিন settings থেকে';
  static const recordingStartFailed = 'রেকর্ডিং শুরু করা যায়নি';
  static const recordingStopFailed = 'রেকর্ডিং বন্ধ করা যায়নি';
  static const voiceMessageMissing = 'Voice message পাওয়া যায়নি';
  static const transcriptionFailed = 'কথা বোঝা যায়নি, আবার বলুন';
  static const ocrFailed = 'Receipt পড়া যায়নি, আবার চেষ্টা করুন';
  static const notReceipt = 'এটা receipt মনে হচ্ছে না';
  static const receiptTextNotFound =
      'Receipt এ লেখা পড়া যাচ্ছে না।\nভালো আলোতে সরাসরি ধরুন।';
  static const receiptInvalidFormat =
      'Receipt format ঠিক নেই। দোকানের নাম, item আর total একসাথে দেখান।';
  static const receiptScanFailed = 'Receipt scan করা যায়নি';
  static const receiptAutoCrop = 'Receipt auto-crop করা হয়েছে for better OCR.';
  static const recordingTooLong = 'Recording too long. ২ মিনিটের মধ্যে রাখুন।';
  static const recordingFileMissing = 'Recording file পাওয়া যায়নি।';
  static const openAiEmptyResponse = 'OpenAI returned an empty response.';

  static const appName = 'SmartSpend';
  static const tagline = 'AI দিয়ে খরচ ট্র্যাক করুন';
  static const poweredBy = 'Powered by OpenAI';
  static const saveButton = 'Save করুন';
  static const cancelButton = 'বাদ দিন';
  static const chatHint = 'খরচ লিখুন বা বলুন...';
  static const welcomeTitle = 'SmartSpend এ স্বাগতম';
  static const welcomeSubtitle = 'খরচ লিখুন বা বলুন';
  static const expenseLabel = 'খরচ';
  static const voiceMessage = '🎤 ভয়েস মেসেজ';
  static const voiceMessageLabel = 'ভয়েস মেসেজ';
  static const transcriptHidden = 'Transcript দেখা যাচ্ছে না';
  static const voiceRecording = 'ভয়েস রেকর্ড হচ্ছে';
  static const voiceSendInstruction = 'শেষ হলে পাশের বাটনে চাপুন';
  static const sendNow = 'পাঠান';
  static const receiptScanned = 'Receipt scan করলাম';
  static const receiptSource = 'ML Kit + OpenAI';
  static const receiptDetected = 'Receipt detected';
  static const exportError = 'Export করতে সমস্যা হয়েছে';
  static const exportNoExpenses = 'এই সময়ে কোনো expense নেই';
  static const exportShareSubject = 'SmartSpend Expense Report';
  static const exportSuccess = 'CSV export তৈরি হয়েছে';

  static const expenseSaved = 'Expense save হয়েছে!';
  static const expenseDeleted = 'Expense মুছে গেছে';
  static const allDataCleared = 'সব data clear করা হয়েছে';
  static const demoDataSeeded = 'Demo data যোগ করা হয়েছে';
  static const githubCopied = 'GitHub link copied';
  static const noExpenseToSave = 'Save করার মতো খরচ পাওয়া যায়নি';

  static String expensesSaved(int count) => '$countটি expense save হয়েছে';
  static String expensesSavedWithCount(String countLabel) =>
      '$countLabelটি expense save হয়েছে';
}
