import '../entities/driver_entity.dart';
import '../repositories/home_repository.dart';

class GetNearbyDriversUsecase {
  final HomeRepository _repository;
  const GetNearbyDriversUsecase(this._repository);

  Future<List<DriverEntity>> call({
    required double lat,
    required double lng,
    double radiusMeters = 5000,
  }) async {
    return _repository.getNearbyDrivers(
      lat:          lat,
      lng:          lng,
      radiusMeters: radiusMeters,
    );
  }
}
