import 'dart:convert';

import 'package:isar_community/isar.dart';

part 'net_worth_snapshot_model.g.dart';

/// One recorded মোট সম্পদ for a calendar day (forward-only history).
///
/// There is no backfill: wallet opening balances and debt principal bypass the
/// expense records, so any reconstruction would be silently wrong. History starts
/// on the first snapshot.
@collection
class NetWorthSnapshotModel {
  Id id = Isar.autoIncrement;

  /// Local calendar day of capture as `yyyymmdd` (an int, not a DateTime, so a
  /// time-zone change can never split or merge days). One row per day.
  ///
  /// Uniqueness is enforced by `NetWorthSnapshotService` inside its write
  /// transaction rather than with `@Index(unique: true)`: a unique index makes
  /// Isar generate `*ByIndex` helpers that the analyzer flags as experimental.
  @Index()
  late int dayKey;

  /// The real instant of the latest refresh — never faked to a month-end.
  late DateTime capturedAt;

  /// First write of this [dayKey].
  late DateTime createdAt;

  /// `netWorthOf(wallets)` — identical to what `totalBalanceProvider` shows.
  late double total;

  /// `[{"id":1,"name":"নগদ","balance":123.0}, …]` for the wallets that make up
  /// [total] (non-archived only, so Σ balance == total). JSON so fields can be
  /// added later without a schema change.
  late String perWalletJson;

  @ignore
  List<SnapshotWallet> get perWallet {
    final decoded = jsonDecode(perWalletJson);
    if (decoded is! List) {
      return const [];
    }
    return [
      for (final row in decoded)
        if (row is Map)
          SnapshotWallet(
            id: (row['id'] as num?)?.toInt() ?? 0,
            name: row['name']?.toString() ?? '',
            balance: (row['balance'] as num?)?.toDouble() ?? 0,
          ),
    ];
  }
}

class SnapshotWallet {
  const SnapshotWallet({
    required this.id,
    required this.name,
    required this.balance,
  });

  final int id;
  final String name;
  final double balance;

  Map<String, Object> toJson() => {'id': id, 'name': name, 'balance': balance};
}

/// `2026-10-06` -> `20261006`.
int dayKeyOf(DateTime date) => date.year * 10000 + date.month * 100 + date.day;

/// `20261006` -> local midnight of that day.
DateTime dateOfDayKey(int dayKey) =>
    DateTime(dayKey ~/ 10000, (dayKey ~/ 100) % 100, dayKey % 100);
