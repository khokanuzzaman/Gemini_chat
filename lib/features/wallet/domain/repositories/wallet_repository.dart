import '../entities/wallet_entity.dart';

abstract class WalletRepository {
  Future<List<WalletEntity>> getAllWallets();
  Future<WalletEntity?> getWalletById(int id);
  Future<WalletEntity> saveWallet(WalletEntity wallet);
  Future<void> deleteWallet(int id);
  Future<void> archiveWallet(int id);
  Future<void> adjustBalance(int walletId, double delta);
}
