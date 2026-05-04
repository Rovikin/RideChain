import '../entities/dispute_entity.dart';

abstract class DisputeRepository {
  /// Get dispute by session ID
  Future<DisputeEntity> getDisputeBySession(String sessionId);

  /// Open dispute — passenger only, requires arbiter fee
  Future<DisputeEntity> openDispute(String sessionId, BigInt arbiterFee);

  /// Rate arbiter after resolution
  Future<void> rateArbiter(String disputeId, int rating);

  /// Trigger reassignment if arbiter timed out
  Future<void> triggerReassignment(String disputeId);
}
