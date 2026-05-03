import '../entities/order_entity.dart';
import '../../../home/domain/entities/driver_entity.dart';

abstract class OrderRepository {
  /// Calculate route and fare estimate for selected driver
  Future<Map<String, dynamic>> calculateFare({
    required String driverAddress,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
  });

  /// Submit order on-chain and lock escrow
  Future<OrderEntity> createOrder({
    required String driverAddress,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required String pickupLabel,
    required String dropoffLabel,
    required int    estimatedDistanceMeters,
    required String routingNodeAddress,
  });

  /// Get order status by ID
  Future<OrderEntity> getOrder(String orderId);
}
