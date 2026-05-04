import 'package:equatable/equatable.dart';

abstract class TripEvent extends Equatable {
  const TripEvent();
  @override
  List<Object?> get props => [];
}

class TripLoadRequested extends TripEvent {
  final String sessionId;
  const TripLoadRequested(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}

class TripWatchStarted extends TripEvent {
  final String sessionId;
  const TripWatchStarted(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}

class TripStateUpdated extends TripEvent {
  final dynamic trip;
  const TripStateUpdated(this.trip);
  @override
  List<Object?> get props => [trip];
}

class TripAcceptRequested extends TripEvent {
  final String sessionId;
  const TripAcceptRequested(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}

class TripArrivedAtPickup extends TripEvent {
  final String sessionId;
  const TripArrivedAtPickup(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}

class TripStartRequested extends TripEvent {
  final String sessionId;
  const TripStartRequested(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}

class TripCompleteRequested extends TripEvent {
  final String sessionId;
  final String merkleRoot;
  const TripCompleteRequested(this.sessionId, this.merkleRoot);
  @override
  List<Object?> get props => [sessionId, merkleRoot];
}

class TripConfirmRequested extends TripEvent {
  final String sessionId;
  const TripConfirmRequested(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}

class TripCancelRequested extends TripEvent {
  final String sessionId;
  const TripCancelRequested(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}

class TripDisputeRequested extends TripEvent {
  final String sessionId;
  const TripDisputeRequested(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}

class TripPanicActivated extends TripEvent {
  final String sessionId;
  final String locationHash;
  const TripPanicActivated(this.sessionId, this.locationHash);
  @override
  List<Object?> get props => [sessionId, locationHash];
}
