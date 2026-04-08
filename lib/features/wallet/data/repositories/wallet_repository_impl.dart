import '../../../../core/database/models/wallet_model.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_local_datasource.dart';

class WalletRepositoryImpl implements WalletRepository {
  const WalletRepositoryImpl({required WalletLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  final WalletLocalDataSource _localDataSource;

  @override
  Future<List<WalletEntity>> getAllWallets() async {
    try {
      final wallets = await _localDataSource.getAllWallets();
      return wallets.map((wallet) => wallet.toEntity()).toList(growable: false);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<WalletEntity?> getWalletById(int id) async {
    try {
      final wallet = await _localDataSource.getWalletById(id);
      return wallet?.toEntity();
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<WalletEntity> saveWallet(WalletEntity wallet) async {
    try {
      final savedWallet = await _localDataSource.saveWallet(wallet.toModel());
      return savedWallet.toEntity();
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<void> deleteWallet(int id) async {
    try {
      await _localDataSource.deleteWallet(id);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<void> archiveWallet(int id) async {
    try {
      await _localDataSource.archiveWallet(id);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<void> adjustBalance(int walletId, double delta) async {
    try {
      await _localDataSource.adjustBalance(walletId, delta);
    } catch (_) {
      throw const StorageFailure();
    }
  }
}

extension on WalletEntity {
  WalletModel toModel() => WalletModel.fromEntity(this);
}
