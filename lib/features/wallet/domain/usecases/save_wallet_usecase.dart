import '../entities/wallet_entity.dart';
import '../repositories/wallet_repository.dart';

class SaveWalletUseCase {
  const SaveWalletUseCase(this._repository);

  final WalletRepository _repository;

  Future<WalletEntity> call(WalletEntity wallet) {
    return _repository.saveWallet(wallet);
  }
}
