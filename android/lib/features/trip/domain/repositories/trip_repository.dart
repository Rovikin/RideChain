import '../entities/trip_entity.dart';

abstract class TripRepository {
  /// Get current trip session state from chain
  Future<TripEntity> getTrip(String sessionId);

  /// Driver: accept order
  Future<void> acceptOrder(String sessionId);

  /// Driver: signal arrived at pickup
  Future<void> arrivedAtPickup(String sessionId);

  /// Driver: start trip (passenger on board)
  Future<void> startTrip(String sessionId);

  /// Driver: complete trip with GPS merkle root
  Future<void> completeTrip(String sessionId, String gpsMerkleRoot);

  /// Passenger: confirm trip completed
  Future<void> confirmTrip(String sessionId);

  /// Passenger: cancel trip (rules-based penalty)
  Future<void> cancelTrip(String sessionId);

  /// Anyone: trigger timeout resolution
  Future<void> triggerTimeout(String sessionId);

  /// Stream trip state changes
  Stream<TripEntity> watchTrip(String sessionId);
}
