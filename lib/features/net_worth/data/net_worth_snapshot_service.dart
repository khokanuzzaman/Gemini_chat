import 'dart:convert';

import 'package:isar_community/isar.dart';

import '../../../core/database/models/wallet_model.dart';
import '../../../core/logging/app_logger.dart';
import '../../wallet/data/datasources/wallet_local_datasource.dart';
import '../../wallet/data/repositories/wallet_repository_impl.dart';
import '../../wallet/domain/entities/net_worth.dart';
import '../../wallet/domain/repositories/wallet_repository.dart';
import 'models/net_worth_snapshot_model.dart';
import 'net_worth_snapshot_retention.dart';

/// Records মোট সম্পদ once per day (G1). Open-based: call on first frame and on
/// resume; there is no background worker, so days the app wasn't opened are gaps
/// (shown as gaps, never invented).
class NetWorthSnapshotService {
  NetWorthSnapshotService({
    required Isar isar,
    WalletRepository? walletRepository,
    DateTime Function()? clock,
    this.minInterval = const Duration(seconds: 30),
  }) : _isar = isar,
       _walletRepository =
           walletRepository ??
           WalletRepositoryImpl(localDataSource: WalletLocalDataSource(isar)),
       _clock = clock ?? DateTime.now;

  final Isar _isar;
  final WalletRepository _walletRepository;
  final DateTime Function() _clock;

  /// Resumes are frequent; skip re-reading wallets if we just did.
  final Duration minInterval;
  DateTime? _lastRunAt;

  /// Writes today's snapshot if it is missing, or refreshes it when the total or
  /// any per-wallet balance changed. Never throws — a failure here must not
  /// affect app start. Returns true if a row was written.
  Future<bool> captureIfNeeded({bool force = false}) async {
    try {
      return await _capture(force: force);
    } catch (error) {
      AppLogger.debug('net-worth snapshot failed: ${error.runtimeType}');
      return false;
    }
  }

  Future<bool> _capture({required bool force}) async {
    final now = _clock();
    final lastRun = _lastRunAt;
    if (!force && lastRun != null && now.difference(lastRun) < minInterval) {
      return false;
    }
    _lastRunAt = now;

    // No wallet rows at all (fresh install / after delete-all) is "nothing to
    // record", not a net worth of zero.
    if (await _isar.walletModels.count() == 0) {
      return false;
    }

    final dayKey = dayKeyOf(now);
    final latest = await _isar.netWorthSnapshotModels
        .where()
        .sortByDayKeyDesc()
        .findFirst();
    if (latest != null && dayKey < latest.dayKey) {
      // Clock moved backwards: never back-date or overwrite the past.
      return false;
    }

    // Same source and ordering as `totalBalanceProvider` (see netWorthOf).
    final wallets = sortedBySortOrder(await _walletRepository.getAllWallets());
    final total = netWorthOf(wallets);
    final perWalletJson = jsonEncode([
      for (final wallet in wallets)
        if (!wallet.isArchived)
          SnapshotWallet(
            id: wallet.id,
            name: wallet.name,
            balance: wallet.currentBalance,
          ).toJson(),
    ]);

    // Check-then-write inside ONE transaction (Isar serialises them), which is
    // what makes "one row per dayKey" hold even if two captures race.
    return _isar.writeTxn(() async {
      final existing = await _isar.netWorthSnapshotModels
          .filter()
          .dayKeyEqualTo(dayKey)
          .findFirst();
      if (existing != null &&
          existing.total == total &&
          existing.perWalletJson == perWalletJson) {
        return false;
      }

      await _isar.netWorthSnapshotModels.put(
        NetWorthSnapshotModel()
          ..id = existing?.id ?? Isar.autoIncrement
          ..dayKey = dayKey
          ..capturedAt = now
          ..createdAt = existing?.createdAt ?? now
          ..total = total
          ..perWalletJson = perWalletJson,
      );
      if (existing == null) {
        await _applyRetention(now);
      }
      return true;
    });
  }

  Future<void> _applyRetention(DateTime today) async {
    final all = await _isar.netWorthSnapshotModels.where().findAll();
    final ids = snapshotIdsToDelete([
      for (final row in all) (id: row.id, dayKey: row.dayKey),
    ], today: today);
    if (ids.isNotEmpty) {
      await _isar.netWorthSnapshotModels.deleteAll(ids.toList());
    }
  }

  /// All snapshots, oldest first (for the future trend chart / tests).
  Future<List<NetWorthSnapshotModel>> all() {
    return _isar.netWorthSnapshotModels.where().sortByDayKey().findAll();
  }
}
