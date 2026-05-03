import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../home/domain/entities/driver_entity.dart';

class LocationPicker extends StatefulWidget {
  final DriverEntity driver;
  final void Function(
    double pickupLat,
    double pickupLng,
    double dropoffLat,
    double dropoffLng,
    String pickupLabel,
    String dropoffLabel,
  ) onLocationConfirmed;

  const LocationPicker({
    super.key,
    required this.driver,
    required this.onLocationConfirmed,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final _dropoffController = TextEditingController();

  double? _pickupLat;
  double? _pickupLng;
  double? _dropoffLat;
  double? _dropoffLng;
  String  _pickupLabel  = 'Lokasi saat ini';
  bool    _isLocating   = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _dropoffController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _pickupLat   = pos.latitude;
        _pickupLng   = pos.longitude;
        _pickupLabel = 'Lokasi saat ini (${pos.latitude.toStringAsFixed(4)}, '
            '${pos.longitude.toStringAsFixed(4)})';
        _isLocating  = false;
      });
    } catch (e) {
      setState(() => _isLocating = false);
    }
  }

  void _confirm() {
    if (_pickupLat == null || _dropoffLat == null) return;
    widget.onLocationConfirmed(
      _pickupLat!, _pickupLng!,
      _dropoffLat!, _dropoffLng!,
      _pickupLabel,
      _dropoffController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // driver info banner
          Container(
            padding:    const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:        Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_bike),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.driver.address.substring(0, 6)}...${widget.driver.address.substring(widget.driver.address.length - 4)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '⭐ ${widget.driver.reputationDisplay}  •  '
                        '${(widget.driver.distanceMeters / 1000).toStringAsFixed(1)} km dari Anda',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // pickup location
          Text(
            'Titik Jemput',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Container(
            padding:    const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:        Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.my_location, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: _isLocating
                      ? const Text('Mendapatkan lokasi...')
                      : Text(_pickupLabel),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // dropoff location
          Text(
            'Tujuan',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _dropoffController,
            decoration: const InputDecoration(
              hintText:    'Masukkan alamat tujuan',
              prefixIcon:  Icon(Icons.location_on, color: Colors.red),
            ),
            onChanged: (value) {
              // TODO: integrate geocoding / address search
              // For now use hardcoded test coordinates
              if (value.isNotEmpty) {
                setState(() {
                  _dropoffLat = -6.210;
                  _dropoffLng = 106.820;
                });
              }
            },
          ),

          const Spacer(),

          ElevatedButton(
            onPressed: (_pickupLat != null &&
                _dropoffLat != null &&
                _dropoffController.text.isNotEmpty)
                ? _confirm
                : null,
            child: const Text('Hitung Tarif'),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
