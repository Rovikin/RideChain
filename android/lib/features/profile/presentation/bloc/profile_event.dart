import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {
  final String address;
  const ProfileLoadRequested(this.address);
  @override
  List<Object?> get props => [address];
}

class ProfileDriverRegistered extends ProfileEvent {
  final String kycHash;
  final BigInt depositWei;
  const ProfileDriverRegistered(this.kycHash, this.depositWei);
  @override
  List<Object?> get props => [kycHash, depositWei];
}

class ProfilePassengerRegistered extends ProfileEvent {
  final String kycHash;
  const ProfilePassengerRegistered(this.kycHash);
  @override
  List<Object?> get props => [kycHash];
}

class ProfileFareUpdated extends ProfileEvent {
  final BigInt farePerKm;
  const ProfileFareUpdated(this.farePerKm);
  @override
  List<Object?> get props => [farePerKm];
}

class ProfileDepositToppedUp extends ProfileEvent {
  final BigInt amountWei;
  const ProfileDepositToppedUp(this.amountWei);
  @override
  List<Object?> get props => [amountWei];
}
