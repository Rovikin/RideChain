import '../repositories/profile_repository.dart';

class RegisterDriverUsecase {
  final ProfileRepository _repository;
  const RegisterDriverUsecase(this._repository);

  Future<void> call(String kycHash, BigInt depositWei) =>
      _repository.registerAsDriver(kycHash, depositWei);
}
