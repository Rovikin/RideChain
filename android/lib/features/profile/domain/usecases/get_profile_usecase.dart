import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class GetProfileUsecase {
  final ProfileRepository _repository;
  const GetProfileUsecase(this._repository);

  Future<ProfileEntity> call(String address) =>
      _repository.getProfile(address);
}
