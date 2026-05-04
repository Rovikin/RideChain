import '../repositories/trip_repository.dart';

class ConfirmTripUsecase {
  final TripRepository _repository;
  const ConfirmTripUsecase(this._repository);

  Future<void> call(String sessionId) =>
      _repository.confirmTrip(sessionId);
}
