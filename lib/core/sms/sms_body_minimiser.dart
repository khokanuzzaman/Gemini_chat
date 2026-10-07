import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/models/sms_ledger_entry_model.dart';
import 'sms_match_hints.dart';

/// One-time upgrade step: blanks the SMS text that earlier versions stored on
/// every ledger row, keeping only what the app still needs.
///
/// Per row, in this order: the matcher hints are derived from the text (so
/// wallet/category suggestions do not change), THEN the text is blanked. The
/// signature, sender, amount, dates, reference… are untouched, so duplicate
/// detection (which compares signatures hashed from the live inbox message) keeps
/// working. Idempotent and safe to re-run; it never deletes a row.
///
/// Honest limit: Isar's storage engine does not zero freed pages, so a blanked
/// text can remain in unused space of the database file until that space is
/// reused. The text is gone from the app, from new backups, and from every query.
class SmsBodyMinimiser {
  const SmsBodyMinimiser._();

  static const doneKey = 'sms_bodies_stripped_v1';
  static const _batch = 200;

  /// Returns how many rows were blanked (0 when already done).
  static Future<int> run(Isar isar, SharedPreferences prefs) async {
    if (prefs.getBool(doneKey) ?? false) {
      return 0;
    }
    final custom = SmsMatchHints.currentCustomCategoryNames.toList();
    var stripped = 0;
    while (true) {
      final rows = await isar.smsLedgerEntryModels
          .filter()
          .not()
          .rawMessageEqualTo('')
          .limit(_batch)
          .findAll();
      if (rows.isEmpty) {
        break;
      }
      for (final row in rows) {
        row.matchHints ??= SmsMatchHints.extract(
          row.rawMessage,
          customCategoryNames: custom,
        );
        row.rawMessage = '';
      }
      await isar.writeTxn(() => isar.smsLedgerEntryModels.putAll(rows));
      stripped += rows.length;
    }
    await prefs.setBool(doneKey, true);
    return stripped;
  }
}
