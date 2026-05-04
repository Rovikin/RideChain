import '../entities/dispute_entity.dart';
import '../repositories/dispute_repository.dart';

class OpenDisputeUsecase {
  final DisputeRepository _repository;
  const OpenDisputeUsecase(this._repository);

  Future<DisputeEntity> call(String sessionId, BigInt arbiterFee) =>
      _repository.openDispute(sessionId, arbiterFee);
}
