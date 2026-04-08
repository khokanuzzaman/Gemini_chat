import 'package:isar/isar.dart';

import '../../../../core/database/models/wallet_model.dart';
import '../../domain/entities/wallet_defaults.dart';

class WalletLocalDataSource {
  const WalletLocalDataSource(this._isar);

  final Isar _isar;

  Future<void> seedDefaultWallets() async {
    final existingWallets = await _isar.walletModels.where().findAll();
    if (existingWallets.isNotEmpty) {
      return;
    }

    final models = defaultWallets
        .map(WalletModel.fromEntity)
        .toList(growable: false);
    await _isar.writeTxn(() async {
      await _isar.walletModels.putAll(models);
    });
  }

  Future<List<WalletModel>> getAllWallets() async {
    final wallets = await _isar.walletModels.where().findAll();
    final activeWallets = wallets
        .where((wallet) => !wallet.isArchived)
        .toList(growable: false);
    activeWallets.sort(
      (first, second) => first.sortOrder.compareTo(second.sortOrder),
    );
    return activeWallets;
  }

  Future<List<WalletModel>> getAllWalletsIncludingArchived() async {
    final wallets = await _isar.walletModels.where().findAll();
    wallets.sort(
      (first, second) => first.sortOrder.compareTo(second.sortOrder),
    );
    return wallets;
  }

  Future<WalletModel?> getWalletById(int id) {
    return _isar.walletModels.get(id);
  }

  Future<WalletModel> saveWallet(WalletModel wallet) async {
    await _isar.writeTxn(() async {
      final savedId = await _isar.walletModels.put(wallet);
      wallet.id = savedId;
    });
    return wallet;
  }

  Future<bool> deleteWallet(int id) async {
    var deleted = false;
    await _isar.writeTxn(() async {
      deleted = await _isar.walletModels.delete(id);
    });
    return deleted;
  }

  Future<void> archiveWallet(int id) async {
    await _isar.writeTxn(() async {
      final wallet = await _isar.walletModels.get(id);
      if (wallet == null) {
        return;
      }

      wallet
        ..isArchived = true
        ..updatedAt = DateTime.now();
      await _isar.walletModels.put(wallet);
    });
  }

  Future<void> adjustBalance(int walletId, double delta) async {
    await _isar.writeTxn(() async {
      final wallet = await _isar.walletModels.get(walletId);
      if (wallet == null) {
        return;
      }

      wallet
        ..currentBalance += delta
        ..updatedAt = DateTime.now();
      await _isar.walletModels.put(wallet);
    });
  }
}
