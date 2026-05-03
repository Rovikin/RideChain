import '../repositories/auth_repository.dart';

class CreateWalletUsecase {
  final AuthRepository _repository;
  const CreateWalletUsecase(this._repository);

  /// Returns mnemonic phrase — must be shown to user exactly once
  Future<String> call() async {
    return _repository.createWallet();
  }
}
