import 'package:equatable/equatable.dart';

abstract class DisputeEvent extends Equatable {
  const DisputeEvent();
  @override
  List<Object?> get props => [];
}

class DisputeLoadRequested extends DisputeEvent {
  final String sessionId;
  const DisputeLoadRequested(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}

class DisputeOpenRequested extends DisputeEvent {
  final String sessionId;
  final BigInt arbiterFee;
  const DisputeOpenRequested(this.sessionId, this.arbiterFee);
  @override
  List<Object?> get props => [sessionId, arbiterFee];
}

class DisputeArbiterRated extends DisputeEvent {
  final String disputeId;
  final int    rating;
  const DisputeArbiterRated(this.disputeId, this.rating);
  @override
  List<Object?> get props => [disputeId, rating];
}

class DisputeReassignmentTriggered extends DisputeEvent {
  final String disputeId;
  const DisputeReassignmentTriggered(this.disputeId);
  @override
  List<Object?> get props => [disputeId];
}
