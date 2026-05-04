import '../repositories/trip_repository.dart';

class CompleteTripUsecase {
  final TripRepository _repository;
  const CompleteTripUsecase(this._repository);

  Future<void> call(String sessionId, String merkleRoot) =>
      _repository.completeTrip(sessionId, merkleRoot);
}
