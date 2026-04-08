import '../entities/wallet_entity.dart';
import '../repositories/wallet_repository.dart';

class GetWalletsUseCase {
  const GetWalletsUseCase(this._repository);

  final WalletRepository _repository;

  Future<List<WalletEntity>> call() {
    return _repository.getAllWallets();
  }
}
