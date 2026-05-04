import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  final String  address;
  final bool    isDriver;
  final bool    isPassenger;
  final bool    isArbiter;
  final int     reputationScore;
  final int     totalTrips;
  final BigInt  depositAmount;
  final BigInt  maxOrderValue;
  final BigInt? farePerKm;
  final bool    active;

  const ProfileEntity({
    required this.address,
    required this.isDriver,
    required this.isPassenger,
    required this.isArbiter,
    required this.reputationScore,
    required this.totalTrips,
    required this.depositAmount,
    required this.maxOrderValue,
    this.farePerKm,
    required this.active,
  });

  String get reputationDisplay =>
      (reputationScore / 100).toStringAsFixed(1);

  String get shortAddress =>
      '${address.substring(0, 6)}...${address.substring(address.length - 4)}';

  @override
  List<Object?> get props => [address, reputationScore, depositAmount];
}
