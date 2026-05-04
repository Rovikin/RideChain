import '../repositories/profile_repository.dart';

class SetFareUsecase {
  final ProfileRepository _repository;
  const SetFareUsecase(this._repository);

  Future<void> call(BigInt farePerKm) =>
      _repository.setFarePerKm(farePerKm);
}
