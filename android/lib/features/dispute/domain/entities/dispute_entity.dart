import 'package:equatable/equatable.dart';

enum DisputeStatus { pending, inReview, resolved, reassigned }

class DisputeEntity extends Equatable {
  final String        disputeId;
  final String        sessionId;
  final String        driverAddress;
  final String        passengerAddress;
  final String        arbiterAddress;
  final BigInt        arbiterFee;
  final DisputeStatus status;
  final bool          driverWins;
  final DateTime      createdAt;
  final DateTime      resolveDeadline;

  const DisputeEntity({
    required this.disputeId,
    required this.sessionId,
    required this.driverAddress,
    required this.passengerAddress,
    required this.arbiterAddress,
    required this.arbiterFee,
    required this.status,
    required this.driverWins,
    required this.createdAt,
    required this.resolveDeadline,
  });

  bool get isResolved => status == DisputeStatus.resolved;

  bool get isExpired =>
      !isResolved && DateTime.now().isAfter(resolveDeadline);

  @override
  List<Object?> get props => [disputeId, status, driverWins];
}
