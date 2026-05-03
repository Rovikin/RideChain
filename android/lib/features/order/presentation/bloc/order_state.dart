import 'package:equatable/equatable.dart';
import '../../../home/domain/entities/driver_entity.dart';
import '../../domain/entities/order_entity.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLocationPicking extends OrderState {
  final DriverEntity driver;
  const OrderLocationPicking(this.driver);

  @override
  List<Object?> get props => [driver];
}

class OrderFareLoading extends OrderState {}

class OrderFareLoaded extends OrderState {
  final DriverEntity       driver;
  final int                distanceMeters;
  final int                durationSeconds;
  final BigInt             fare;
  final BigInt             routingFee;
  final BigInt             total;
  final double             pickupLat;
  final double             pickupLng;
  final double             dropoffLat;
  final double             dropoffLng;
  final String             pickupLabel;
  final String             dropoffLabel;

  const OrderFareLoaded({
    required this.driver,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.fare,
    required this.routingFee,
    required this.total,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.pickupLabel,
    required this.dropoffLabel,
  });

  @override
  List<Object?> get props => [
    driver, distanceMeters, fare, routingFee, total,
  ];
}

class OrderSubmitting extends OrderState {}

class OrderSuccess extends OrderState {
  final OrderEntity order;
  const OrderSuccess(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderError extends OrderState {
  final String message;
  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}
