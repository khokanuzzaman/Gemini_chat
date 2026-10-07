import '../../features/category/domain/category_registry.dart';
import 'sms_category_mapper.dart';
import 'sms_wallet_matcher.dart';

/// What the SMS ledger keeps INSTEAD of the message text.
///
/// The wallet matcher and category/income-source mapper only ever ask "does the
/// text contain one of these known words?". So at ingest — while the message is
/// still in memory — we record WHICH of those known words it contained and throw
/// the message away. Matching against the hint string gives the same answer as
/// matching against the body did, but no sentence, balance, name or number is
/// ever written to disk (or into a backup).
///
/// The vocabulary is exactly the matchers' own keyword lists plus the user's
/// custom category names (the mapper tests those too), so the two cannot drift.
class SmsMatchHints {
  const SmsMatchHints._();

  /// Separator that cannot occur inside a keyword, so two single-word hints can
  /// never accidentally form a multi-word keyword ("food" + "court").
  static const separator = ' | ';

  /// The user's non-default category names right now (the mapper matches them).
  static Iterable<String> get currentCustomCategoryNames => CategoryRegistry
      .categories
      .where((category) => !category.isDefault)
      .map((category) => category.name);

  /// The known words found in [body] (case-insensitive), `' | '`-joined; `''` if
  /// none. [customCategoryNames] are the user's non-default category names.
  static String extract(
    String body, {
    Iterable<String> customCategoryNames = const [],
  }) {
    final text = body.toLowerCase();
    if (text.trim().isEmpty) {
      return '';
    }
    final found = <String>{};
    void scan(Iterable<String> words) {
      for (final word in words) {
        final needle = word.trim().toLowerCase();
        if (needle.isNotEmpty && text.contains(needle)) {
          found.add(needle);
        }
      }
    }

    for (final words in SmsWalletMatcher.bankKeywordMap.values) {
      scan(words);
    }
    for (final words in SmsCategoryMapper.expenseKeywordMap.values) {
      scan(words);
    }
    scan(SmsCategoryMapper.salaryKeywords);
    scan(SmsCategoryMapper.freelanceKeywords);
    scan(SmsCategoryMapper.companyMarkers);
    scan(customCategoryNames);
    return found.join(separator);
  }
}
