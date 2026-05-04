import '../entities/dispute_entity.dart';
import '../repositories/dispute_repository.dart';

class GetDisputeUsecase {
  final DisputeRepository _repository;
  const GetDisputeUsecase(this._repository);

  Future<DisputeEntity> call(String sessionId) =>
      _repository.getDisputeBySession(sessionId);
}
