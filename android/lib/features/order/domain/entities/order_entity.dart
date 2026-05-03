import 'package:equatable/equatable.dart';

enum OrderStatus {
  pending,
  matched,
  accepted,
  pickingUp,
  inProgress,
  completed,
  confirmed,
  disputed,
  resolved,
  cancelled,
  expired,
}

class OrderEntity extends Equatable {
  final String      orderId;
  final String      driverAddress;
  final String      passengerAddress;
  final double      pickupLat;
  final double      pickupLng;
  final double      dropoffLat;
  final double      dropoffLng;
  final String      pickupLabel;
  final String      dropoffLabel;
  final int         estimatedDistanceMeters;
  final BigInt      estimatedFare;
  final BigInt      routingFee;
  final OrderStatus status;
  final DateTime    createdAt;

  const OrderEntity({
    required this.orderId,
    required this.driverAddress,
    required this.passengerAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.pickupLabel,
    required this.dropoffLabel,
    required this.estimatedDistanceMeters,
    required this.estimatedFare,
    required this.routingFee,
    required this.status,
    required this.createdAt,
  });

  double get distanceKm => estimatedDistanceMeters / 1000;

  String get distanceDisplay =>
      '${distanceKm.toStringAsFixed(1)} km';

  String get totalFareWei =>
      (estimatedFare + routingFee).toString();

  @override
  List<Object?> get props => [
    orderId,
    driverAddress,
    passengerAddress,
    estimatedDistanceMeters,
    estimatedFare,
    status,
  ];
}
