import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

class CreateOrderUsecase {
  final OrderRepository _repository;
  const CreateOrderUsecase(this._repository);

  Future<OrderEntity> call({
    required String driverAddress,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required String pickupLabel,
    required String dropoffLabel,
    required int    estimatedDistanceMeters,
    required String routingNodeAddress,
  }) async {
    return _repository.createOrder(
      driverAddress:           driverAddress,
      pickupLat:               pickupLat,
      pickupLng:               pickupLng,
      dropoffLat:              dropoffLat,
      dropoffLng:              dropoffLng,
      pickupLabel:             pickupLabel,
      dropoffLabel:            dropoffLabel,
      estimatedDistanceMeters: estimatedDistanceMeters,
      routingNodeAddress:      routingNodeAddress,
    );
  }
}
