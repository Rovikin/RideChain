import '../repositories/dispute_repository.dart';

class RateArbiterUsecase {
  final DisputeRepository _repository;
  const RateArbiterUsecase(this._repository);

  Future<void> call(String disputeId, int rating) =>
      _repository.rateArbiter(disputeId, rating);
}
