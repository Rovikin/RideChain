import 'package:equatable/equatable.dart';

class WalletEntity extends Equatable {
  final String address;
  final int    reputationScore;
  final bool   isDriver;
  final bool   isPassenger;
  final bool   isArbiter;
  final bool   isRegisteredOnChain;

  const WalletEntity({
    required this.address,
    required this.reputationScore,
    required this.isDriver,
    required this.isPassenger,
    required this.isArbiter,
    required this.isRegisteredOnChain,
  });

  bool get hasRole => isDriver || isPassenger || isArbiter;

  @override
  List<Object?> get props => [
    address,
    reputationScore,
    isDriver,
    isPassenger,
    isArbiter,
    isRegisteredOnChain,
  ];
}
