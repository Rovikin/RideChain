import 'package:equatable/equatable.dart';

class DriverEntity extends Equatable {
  final String address;
  final BigInt farePerKm;
  final BigInt depositAmount;
  final BigInt maxOrderValue;
  final int    reputationScore;
  final int    totalTrips;
  final bool   active;
  final int    distanceMeters;

  const DriverEntity({
    required this.address,
    required this.farePerKm,
    required this.depositAmount,
    required this.maxOrderValue,
    required this.reputationScore,
    required this.totalTrips,
    required this.active,
    required this.distanceMeters,
  });

  /// Reputation as displayable string e.g. "4.8"
  String get reputationDisplay {
    final score = reputationScore / 100;
    return score.toStringAsFixed(1);
  }

  /// Fare in IDR-equivalent display (MATIC × IDR rate handled in UI layer)
  String get farePerKmDisplay => farePerKm.toString();

  @override
  List<Object?> get props => [
    address,
    farePerKm,
    depositAmount,
    maxOrderValue,
    reputationScore,
    totalTrips,
    active,
    distanceMeters,
  ];
}
