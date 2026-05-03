import '../repositories/auth_repository.dart';

class ImportWalletUsecase {
  final AuthRepository _repository;
  const ImportWalletUsecase(this._repository);

  Future<void> call(String mnemonic) async {
    return _repository.importWallet(mnemonic);
  }
}
