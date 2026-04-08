import '../repositories/wallet_repository.dart';

class ArchiveWalletUseCase {
  const ArchiveWalletUseCase(this._repository);

  final WalletRepository _repository;

  Future<void> call(int id) {
    return _repository.archiveWallet(id);
  }
}
