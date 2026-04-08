import '../repositories/wallet_repository.dart';

class DeleteWalletUseCase {
  const DeleteWalletUseCase(this._repository);

  final WalletRepository _repository;

  Future<void> call(int id) {
    return _repository.deleteWallet(id);
  }
}
