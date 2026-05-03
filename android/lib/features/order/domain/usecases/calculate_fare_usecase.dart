import '../repositories/order_repository.dart';

class CalculateFareUsecase {
  final OrderRepository _repository;
  const CalculateFareUsecase(this._repository);

  Future<Map<String, dynamic>> call({
    required String driverAddress,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
  }) async {
    return _repository.calculateFare(
      driverAddress: driverAddress,
      pickupLat:     pickupLat,
      pickupLng:     pickupLng,
      dropoffLat:    dropoffLat,
      dropoffLng:    dropoffLng,
    );
  }
}
