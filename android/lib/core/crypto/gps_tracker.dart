import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

import 'merkle_builder.dart';

/// Tracks GPS position during a trip and builds Merkle tree.
/// Runs as foreground service to survive battery optimization.
class GpsTracker {
  final _logger  = Logger();
  final _builder = MerkleBuilder();

  StreamSubscription<Position>? _subscription;
  Timer? _checkpointTimer;

  Position? _lastPosition;
  int       _sequence = 0;
  bool      _isTracking = false;

  // checkpoint every 30 seconds
  static const _checkpointInterval = Duration(seconds: 30);

  // -------------------------
  // Tracking control
  // -------------------------

  Future<void> startTracking() async {
    if (_isTracking) return;

    final permission = await _requestPermission();
    if (!permission) throw GpsException('Location permission denied');

    _isTracking = true;
    _sequence   = 0;

    // listen to position stream
    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy:          LocationAccuracy.high,
        distanceFilter:    10, // meters
      ),
    ).listen(
      (position) {
        _lastPosition = position;
        _logger.d('GPS: ${position.latitude}, ${position.longitude}');
      },
      onError: (e) => _logger.e('GPS error: $e'),
    );

    // add checkpoint every 30 seconds
    _checkpointTimer = Timer.periodic(_checkpointInterval, (_) {
      _addCheckpoint();
    });

    _logger.i('GPS tracking started');
  }

  Future<void> stopTracking() async {
    _isTracking = false;
    await _subscription?.cancel();
    _checkpointTimer?.cancel();
    _logger.i('GPS tracking stopped');
  }

  // -------------------------
  // Merkle root
  // -------------------------

  /// Compute and return Merkle root for on-chain submission.
  /// Called when driver completes trip.
  String computeMerkleRoot() {
    // add final checkpoint before computing root
    _addCheckpoint();
    return _builder.computeRoot();
  }

  int get checkpointCount => _builder.checkpointCount;

  // -------------------------
  // Internal helpers
  // -------------------------

  void _addCheckpoint() {
    if (_lastPosition == null) return;

    _builder.addCheckpoint(
      lat:       _lastPosition!.latitude,
      lng:       _lastPosition!.longitude,
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      sequence:  _sequence++,
    );

    _logger.d('Checkpoint #$_sequence added');
  }

  Future<bool> _requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
           permission == LocationPermission.whileInUse;
  }
}

class GpsException implements Exception {
  final String message;
  const GpsException(this.message);

  @override
  String toString() => 'GpsException: $message';
}
