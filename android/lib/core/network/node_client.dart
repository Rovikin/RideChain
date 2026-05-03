import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// HTTP client for querying RideChain super nodes.
/// Queries multiple nodes and returns majority-consistent result.
class NodeClient {
  final _dio    = Dio();
  final _logger = Logger();

  // known super nodes — in production this comes from on-chain registry
  final List<String> _nodeUrls = [
    'https://node1.ridechain.eth',
    'https://node2.ridechain.eth',
    'https://node3.ridechain.eth',
  ];

  // -------------------------
  // Driver discovery
  // -------------------------

  /// Query nearby drivers from multiple nodes.
  /// Returns list sorted by distance.
  Future<List<DriverPresence>> getNearbyDrivers({
    required double lat,
    required double lng,
    double radiusMeters = 5000,
  }) async {
    final results = await Future.wait(
      _nodeUrls.map((url) => _queryDrivers(url, lat, lng, radiusMeters)),
      eagerError: false,
    );

    // merge results from all nodes, deduplicate by address
    final merged = <String, DriverPresence>{};
    for (final list in results) {
      if (list == null) continue;
      for (final driver in list) {
        merged[driver.address] = driver;
      }
    }

    final drivers = merged.values.toList();
    drivers.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return drivers;
  }

  // -------------------------
  // Routing
  // -------------------------

  /// Request route calculation from multiple nodes.
  /// Returns majority-consistent result.
  Future<RouteResult> getRoute({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
  }) async {
    final results = await Future.wait(
      _nodeUrls.map((url) => _queryRoute(
        url, pickupLat, pickupLng, dropoffLat, dropoffLng,
      )),
      eagerError: false,
    );

    final valid = results.whereType<RouteResult>().toList();
    if (valid.isEmpty) throw NodeException('All nodes unavailable');

    // return median distance for manipulation resistance
    valid.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return valid[valid.length ~/ 2];
  }

  // -------------------------
  // Internal helpers
  // -------------------------

  Future<List<DriverPresence>?> _queryDrivers(
    String nodeUrl,
    double lat,
    double lng,
    double radius,
  ) async {
    try {
      final res = await _dio.get(
        '$nodeUrl/drivers',
        queryParameters: {
          'lat':    lat,
          'lng':    lng,
          'radius': radius,
        },
      ).timeout(const Duration(seconds: 5));

      final data = res.data['drivers'] as List;
      return data.map((d) => DriverPresence.fromJson(d)).toList();
    } catch (e) {
      _logger.w('Node $nodeUrl unreachable: $e');
      return null;
    }
  }

  Future<RouteResult?> _queryRoute(
    String nodeUrl,
    double pickupLat,
    double pickupLng,
    double dropoffLat,
    double dropoffLng,
  ) async {
    try {
      final res = await _dio.post(
        '$nodeUrl/route',
        data: {
          'pickupLat':  pickupLat,
          'pickupLng':  pickupLng,
          'dropoffLat': dropoffLat,
          'dropoffLng': dropoffLng,
        },
      ).timeout(const Duration(seconds: 5));

      return RouteResult.fromJson(res.data);
    } catch (e) {
      _logger.w('Node $nodeUrl route query failed: $e');
      return null;
    }
  }
}

// -------------------------
// Data classes
// -------------------------

class DriverPresence {
  final String address;
  final BigInt farePerKm;
  final int    distanceMeters;
  final int    reputationScore;
  final double lat;
  final double lng;

  const DriverPresence({
    required this.address,
    required this.farePerKm,
    required this.distanceMeters,
    required this.reputationScore,
    required this.lat,
    required this.lng,
  });

  factory DriverPresence.fromJson(Map<String, dynamic> json) {
    return DriverPresence(
      address:         json['address'] as String,
      farePerKm:       BigInt.parse(json['farePerKm'].toString()),
      distanceMeters:  json['distanceMeters'] as int,
      reputationScore: json['reputationScore'] as int,
      lat:             (json['lat'] as num).toDouble(),
      lng:             (json['lng'] as num).toDouble(),
    );
  }
}

class RouteResult {
  final int    distanceMeters;
  final int    durationSeconds;
  final String source;

  const RouteResult({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.source,
  });

  factory RouteResult.fromJson(Map<String, dynamic> json) {
    return RouteResult(
      distanceMeters:  json['distanceMeters'] as int,
      durationSeconds: json['durationSeconds'] as int,
      source:          json['source'] as String,
    );
  }
}

class NodeException implements Exception {
  final String message;
  const NodeException(this.message);

  @override
  String toString() => 'NodeException: $message';
}
