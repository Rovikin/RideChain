import 'package:equatable/equatable.dart';
import '../../../home/domain/entities/driver_entity.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class OrderDriverSelected extends OrderEvent {
  final DriverEntity driver;
  const OrderDriverSelected(this.driver);

  @override
  List<Object?> get props => [driver];
}

class OrderLocationSet extends OrderEvent {
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final String pickupLabel;
  final String dropoffLabel;

  const OrderLocationSet({
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.pickupLabel,
    required this.dropoffLabel,
  });

  @override
  List<Object?> get props => [
    pickupLat, pickupLng,
    dropoffLat, dropoffLng,
  ];
}

class OrderFareRequested extends OrderEvent {}

class OrderSubmitted extends OrderEvent {
  final String routingNodeAddress;
  const OrderSubmitted(this.routingNodeAddress);

  @override
  List<Object?> get props => [routingNodeAddress];
}
