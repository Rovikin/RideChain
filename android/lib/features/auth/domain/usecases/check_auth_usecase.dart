import '../repositories/auth_repository.dart';
import '../entities/wallet_entity.dart';

class CheckAuthUsecase {
  final AuthRepository _repository;
  const CheckAuthUsecase(this._repository);

  Future<WalletEntity?> call() async {
    final hasWallet = await _repository.hasWallet();
    if (!hasWallet) return null;
    return _repository.getWalletInfo();
  }
}
