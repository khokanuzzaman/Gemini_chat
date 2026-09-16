// Feature: Core / Ledger
//
// The SINGLE authority for balance-changing money movement. The ledger owns two
// things and only these two:
//   1. the atomic boundary — every record write and the wallet delta commit
//      together or not at all (Isar `writeTxn` rolls back on any throw), and
//   2. the wallet delta, applied in exactly ONE place.
//
// Callers supply WHAT to write (records), never balances. Different money paths
// write different rows — debt payment writes a DebtPaymentModel + a linked
// ExpenseRecordModel; a goal deposit writes a GoalSavingModel + a linked
// ExpenseRecordModel; income writes an IncomeRecordModel; a plain expense/split
// writes an ExpenseRecordModel — so the write step is a caller-supplied closure
// that runs inside the ledger's transaction. The originating row is written
// first so its id can be read and linked onto the expense record, all atomically.
//
// Guarantees:
//  - Atomic across every write in the closure plus the wallet delta.
//  - Failures surface (missing wallet / failed write throws); nothing swallowed
//    (closes audit C1).
//  - A successful commit never reports failure (closes audit H6): the future
//    completes normally only after everything is committed.
//
// NOTE: this task builds/generalizes the service only. Migrating the existing
// expense / income / debt / split / goal call sites onto it is a later task.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../database/models/expense_record_model.dart';
import '../database/models/wallet_model.dart';
import '../providers/database_providers.dart';

/// Thrown when a ledger operation cannot be completed (e.g. the target wallet
/// does not exist). Surfacing this — rather than returning silently — is what
/// keeps a "successful" result from being reported for money that never moved.
class WalletLedgerException implements Exception {
  const WalletLedgerException(this.message);

  final String message;

  @override
  String toString() => 'WalletLedgerException: $message';
}

/// Ids produced by a ledger write step, carried on [WalletLedgerEntry] so a
/// later flow can reverse the operation. Both slots are optional to cover every
/// money path:
///  - plain expense / split: [expenseRecordId] only
///  - income:                [originatingId] (the IncomeRecordModel id) only
///  - debt payment / goal:   [originatingId] (DebtPaymentModel/GoalSavingModel)
///                           plus [expenseRecordId] (the linked expense record)
class LedgerRecordIds {
  const LedgerRecordIds({this.expenseRecordId, this.originatingId});

  final int? expenseRecordId;
  final int? originatingId;
}

/// The committed result of a ledger operation. Carries what [WalletLedgerService.reverse]
/// needs to undo it: the wallet hit and the signed delta applied (negative =
/// outflow, positive = inflow), plus the ids that were written.
class WalletLedgerEntry {
  const WalletLedgerEntry({
    required this.walletId,
    required this.appliedDelta,
    required this.recordIds,
  });

  final int? walletId;
  final double appliedDelta;
  final LedgerRecordIds recordIds;
}

// SINGLE WRITE PATH: these closures run INSIDE the ledger's writeTxn, so they
// must never call a datasource method that opens its own writeTxn — Isar forbids
// nested transactions. They must also not duplicate persistence logic. The rule
// (established for tasks 3b/3c): each datasource exposes a transaction-FREE
// internal (e.g. `_putExpense(Isar, model)` that assumes it is already inside a
// writeTxn), its public method wraps that internal in writeTxn, and these
// closures call the SAME internal. One write path, two entry points.

/// Runs inside the ledger transaction and writes whatever rows the operation
/// needs, returning their ids. It must NOT touch wallet balances — that is the
/// ledger's job, applied exactly once.
typedef LedgerWriteRecords = Future<LedgerRecordIds> Function(Isar txn);

/// Runs inside the ledger transaction and UPDATES existing rows in place
/// (same ids — record identity survives, so debt/goal sourceId links stay
/// valid), returning their ids. It must NOT touch wallet balances.
typedef LedgerUpdateRecords = Future<LedgerRecordIds> Function(Isar txn);

/// Runs inside the ledger transaction and deletes the rows a reverse must
/// remove. It must NOT touch wallet balances.
typedef LedgerDeleteRecords = Future<void> Function(Isar txn);

class WalletLedgerService {
  const WalletLedgerService(this._isar);

  final Isar _isar;

  /// The general primitive. Writes the caller's records and applies [delta] to
  /// [walletId] — all in one transaction, with the wallet delta applied exactly
  /// once. Pass `walletId: null` with `delta: 0` for a record-only operation.
  Future<WalletLedgerEntry> execute({
    required int? walletId,
    required double delta,
    required LedgerWriteRecords writeRecords,
  }) {
    if (walletId == null && delta != 0) {
      throw ArgumentError('A non-zero delta ($delta) requires a walletId.');
    }
    return _isar.writeTxn(() async {
      // 1) Caller writes its rows first (originating model -> read its id ->
      //    linked expense record), inside this same transaction.
      final ids = await writeRecords(_isar);
      // 2) The ledger applies the wallet delta — the ONE place balances change.
      //    If the wallet is missing, throwing here rolls back the writes above.
      if (walletId != null && delta != 0) {
        await _applyDelta(walletId, delta);
      }
      return WalletLedgerEntry(
        walletId: walletId,
        appliedDelta: delta,
        recordIds: ids,
      );
    });
  }

  /// Convenience for the simple case: money leaving [walletId] recorded as a
  /// single [ExpenseRecordModel]. [amount] must be > 0.
  Future<WalletLedgerEntry> recordOutflow({
    required ExpenseRecordModel record,
    required int walletId,
    required double amount,
  }) async {
    _requirePositive(amount);
    return execute(
      walletId: walletId,
      delta: -amount,
      writeRecords: (isar) async {
        record.walletId = walletId;
        final id = await isar.expenseRecordModels.put(record);
        return LedgerRecordIds(expenseRecordId: id);
      },
    );
  }

  /// Convenience for the simple case: money entering [walletId] recorded as a
  /// single [ExpenseRecordModel]. [amount] must be > 0.
  Future<WalletLedgerEntry> recordInflow({
    required ExpenseRecordModel record,
    required int walletId,
    required double amount,
  }) async {
    _requirePositive(amount);
    return execute(
      walletId: walletId,
      delta: amount,
      writeRecords: (isar) async {
        record.walletId = walletId;
        final id = await isar.expenseRecordModels.put(record);
        return LedgerRecordIds(expenseRecordId: id);
      },
    );
  }

  /// Edits an existing money movement: [updateRecords] updates the row(s) in
  /// place, and the wallet effect is moved from the old version to the new one —
  /// all in one transaction, with each wallet's balance changed exactly once.
  ///
  /// The deltas are the signed amounts each side had/will have applied (the
  /// caller supplies its own sign convention — e.g. expense edit passes
  /// `oldAppliedDelta: -previous`, `newAppliedDelta: -updated`; income passes
  /// `+previous` / `+updated`):
  ///  - same wallet  -> one net delta `(-oldAppliedDelta + newAppliedDelta)`
  ///  - cross wallet -> undo `-oldAppliedDelta` on [oldWalletId] AND apply
  ///                    `newAppliedDelta` on [newWalletId]
  ///  - a null wallet id on either side skips that side (wallet added/removed).
  ///
  /// Returns the entry describing the NEW state (for a later reverse/amend).
  Future<WalletLedgerEntry> amend({
    required LedgerUpdateRecords updateRecords,
    int? oldWalletId,
    double oldAppliedDelta = 0,
    int? newWalletId,
    double newAppliedDelta = 0,
  }) {
    return _isar.writeTxn(() async {
      final ids = await updateRecords(_isar);

      if (oldWalletId != null &&
          newWalletId != null &&
          oldWalletId == newWalletId) {
        final net = -oldAppliedDelta + newAppliedDelta;
        if (net != 0) {
          await _applyDelta(oldWalletId, net);
        }
      } else {
        if (oldWalletId != null && oldAppliedDelta != 0) {
          await _applyDelta(oldWalletId, -oldAppliedDelta);
        }
        if (newWalletId != null && newAppliedDelta != 0) {
          await _applyDelta(newWalletId, newAppliedDelta);
        }
      }

      return WalletLedgerEntry(
        walletId: newWalletId,
        appliedDelta: newAppliedDelta,
        recordIds: ids,
      );
    });
  }

  /// Undoes a previously committed [entry]: the caller-supplied [deleteRecords]
  /// removes every row that was written (multi-record supported) and the ledger
  /// applies the exact inverse balance delta — atomically.
  Future<void> reverse({
    required WalletLedgerEntry entry,
    required LedgerDeleteRecords deleteRecords,
  }) {
    return _isar.writeTxn(() async {
      await deleteRecords(_isar);
      if (entry.walletId != null && entry.appliedDelta != 0) {
        await _applyDelta(entry.walletId!, -entry.appliedDelta);
      }
    });
  }

  /// Applies [delta] to the wallet's balance. MUST be called only inside a
  /// `writeTxn`. This is the single place a wallet balance is mutated.
  Future<void> _applyDelta(int walletId, double delta) async {
    final wallet = await _isar.walletModels.get(walletId);
    if (wallet == null) {
      throw WalletLedgerException(
        'Cannot apply balance change: wallet $walletId not found',
      );
    }
    wallet
      ..currentBalance += delta
      ..updatedAt = DateTime.now();
    await _isar.walletModels.put(wallet);
  }

  void _requirePositive(double amount) {
    if (amount <= 0 || amount.isNaN) {
      throw ArgumentError.value(amount, 'amount', 'must be greater than zero');
    }
  }
}

/// App-wide single instance — the one place wallet balances are mutated.
final walletLedgerServiceProvider = Provider<WalletLedgerService>((ref) {
  return WalletLedgerService(ref.watch(isarProvider));
});
