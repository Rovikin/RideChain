import '../entities/trip_entity.dart';
import '../repositories/trip_repository.dart';

class WatchTripUsecase {
  final TripRepository _repository;
  const WatchTripUsecase(this._repository);

  Stream<TripEntity> call(String sessionId) =>
      _repository.watchTrip(sessionId);
}
