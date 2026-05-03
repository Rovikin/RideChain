import 'package:equatable/equatable.dart';
import '../../domain/entities/driver_entity.dart';
import '../../domain/entities/balance_entity.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final BalanceEntity       balance;
  final List<DriverEntity>  drivers;
  final double?             userLat;
  final double?             userLng;

  const HomeLoaded({
    required this.balance,
    required this.drivers,
    this.userLat,
    this.userLng,
  });

  HomeLoaded copyWith({
    BalanceEntity?      balance,
    List<DriverEntity>? drivers,
    double?             userLat,
    double?             userLng,
  }) {
    return HomeLoaded(
      balance:  balance  ?? this.balance,
      drivers:  drivers  ?? this.drivers,
      userLat:  userLat  ?? this.userLat,
      userLng:  userLng  ?? this.userLng,
    );
  }

  @override
  List<Object?> get props => [balance, drivers, userLat, userLng];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
