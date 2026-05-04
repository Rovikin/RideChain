import '../entities/trip_entity.dart';
import '../repositories/trip_repository.dart';

class GetTripUsecase {
  final TripRepository _repository;
  const GetTripUsecase(this._repository);

  Future<TripEntity> call(String sessionId) =>
      _repository.getTrip(sessionId);
}
