import 'package:equatable/equatable.dart';
import '../../domain/entities/trip_entity.dart';

abstract class TripBlocState extends Equatable {
  const TripBlocState();
  @override
  List<Object?> get props => [];
}

class TripInitial extends TripBlocState {}

class TripLoading extends TripBlocState {}

class TripLoaded extends TripBlocState {
  final TripEntity trip;
  const TripLoaded(this.trip);
  @override
  List<Object?> get props => [trip];
}

class TripActionLoading extends TripBlocState {
  final TripEntity trip;
  final String     action;
  const TripActionLoading(this.trip, this.action);
  @override
  List<Object?> get props => [trip, action];
}

class TripCompleted extends TripBlocState {
  final TripEntity trip;
  const TripCompleted(this.trip);
  @override
  List<Object?> get props => [trip];
}

class TripError extends TripBlocState {
  final String     message;
  final TripEntity? trip;
  const TripError(this.message, {this.trip});
  @override
  List<Object?> get props => [message];
}
