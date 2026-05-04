import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/entities/trip_entity.dart';

class TripMapView extends StatelessWidget {
  final TripEntity trip;
  const TripMapView({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final pickup  = LatLng(trip.pickupLat,  trip.pickupLng);
    final dropoff = LatLng(trip.dropoffLat, trip.dropoffLng);
    final center  = LatLng(
      (trip.pickupLat  + trip.dropoffLat) / 2,
      (trip.pickupLng  + trip.dropoffLng) / 2,
    );

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom:   13,
      ),
      children: [
        TileLayer(
          // OpenStreetMap tiles — no API key required
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.ridechain.app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point:  pickup,
              width:  40,
              height: 40,
              child:  const Icon(
                Icons.circle,
                color: Colors.green,
                size:  20,
              ),
            ),
            Marker(
              point:  dropoff,
              width:  40,
              height: 40,
              child:  const Icon(
                Icons.location_on,
                color: Colors.red,
                size:  32,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
