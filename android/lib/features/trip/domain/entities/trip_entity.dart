import 'package:equatable/equatable.dart';

enum TripState {
  created,
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

class TripEntity extends Equatable {
  final String   sessionId;
  final String   driverAddress;
  final String   passengerAddress;
  final double   pickupLat;
  final double   pickupLng;
  final double   dropoffLat;
  final double   dropoffLng;
  final String   pickupLabel;
  final String   dropoffLabel;
  final int      estimatedDistanceMeters;
  final BigInt   fareAmount;
  final BigInt   escrowAmount;
  final TripState state;
  final String?  gpsMerkleRoot;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TripEntity({
    required this.sessionId,
    required this.driverAddress,
    required this.passengerAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.pickupLabel,
    required this.dropoffLabel,
    required this.estimatedDistanceMeters,
    required this.fareAmount,
    required this.escrowAmount,
    required this.state,
    this.gpsMerkleRoot,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive =>
      state == TripState.accepted ||
      state == TripState.pickingUp ||
      state == TripState.inProgress;

  bool get isCompleted =>
      state == TripState.confirmed ||
      state == TripState.resolved;

  bool get canDispute => state == TripState.completed;
  bool get canConfirm => state == TripState.completed;

  @override
  List<Object?> get props => [
    sessionId, state, gpsMerkleRoot, updatedAt,
  ];
}
