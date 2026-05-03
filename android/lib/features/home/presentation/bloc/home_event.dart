import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeLoadRequested extends HomeEvent {
  final String address;
  const HomeLoadRequested(this.address);

  @override
  List<Object?> get props => [address];
}

class HomeDriversRefreshed extends HomeEvent {
  final double lat;
  final double lng;
  const HomeDriversRefreshed(this.lat, this.lng);

  @override
  List<Object?> get props => [lat, lng];
}

class HomeBalanceRefreshed extends HomeEvent {
  final String address;
  const HomeBalanceRefreshed(this.address);

  @override
  List<Object?> get props => [address];
}
